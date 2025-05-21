import numpy as np
class pe_array:
    def __init__(self, num: int):
        if num < 4:
            raise TypeError("at least 4 PE to ensure enough operands for instruction: MUL-ADD-SFT") 
        self.num = num  # Number of processing elements (PEs)
        self.data_out = np.zeros((2,self.num), dtype=np.uint32)
        self.ins_list = [
        "MADD","MSUB","MMUL","MMAC","KMUL","KMAC","CT-BFO","GS-BFO","P2R",
        "DCP1","DCP2","DCP3","MHINT","UHINT","CHKZ","CHKW0","CHKH",
        "DCMP-1","DCMP-4","DCMP-5","DCMP-10","DCMP-11",
        "CMP-1","CMP-4","CMP-5","CMP-10","CMP-11"]
        self.reset("DSA-44")

    def reset(self, alg: str):
        if alg not in ["KEM-512","KEM-768","KEM-1024","DSA-44","DSA-65","DSA-87"]:
            raise TypeError("invalid algorithm")
        self.q = 3329 if ("KEM" in alg) else 8380417 # modulus
        self.R = pow(2,12,self.q) if ("KEM" in alg) else pow(2,23,self.q) # montgomery factor
        # DSA parameters
        self.D = 13
        self.gamma2 = (self.q-1)//88 if (alg=="DSA-44") else (self.q-1)//32
        self.alpha = (self.q-1)//(2*self.gamma2) # 44 or 16
        self.gamma1 = np.power(2,17) if (alg=="DSA-44") else np.power(2,19)
        self.beta = 78 if (alg=="DSA-44") else (196 if (alg=="DSA-65") else 120)
        # constants for DSA decompose (DCP2) and KEM decompression and compression
        # (see reference c code for DSA, FIPS 203, and test/compress.py)
        self.mulsft_table = {"DCP2":{16: (1025,21), 44:(11275, 23)},
        "DCMP-1":(self.q,0), "DCMP-4":(self.q,3), "DCMP-5":(self.q,4), "DCMP-10":(self.q,9), "DCMP-11":(self.q,10),
        "CMP-1":(10079,23), "CMP-4":(315,15), "CMP-5":(630,15), "CMP-10":(5160669,23), "CMP-11":(5160670,22)}

    def check_input(self, ins: str, data_in: np.ndarray):
        if data_in.dtype != 'uint32': 
            print(data_in.dtype.kind)
            raise TypeError("input data must be uint32 integers")
        if np.any(data_in >= self.q):
            raise ValueError("invalid data range of input data")
        
        if ins not in self.ins_list:
            raise TypeError("invalid instruction for PE")
        elif data_in.shape != (3,self.num):
            raise TypeError("invalid input data shape for PE")
    
    # modular adders (1 pipeline stage)
    # (1 add, 1 cmp, 1 sub, 1 shft)
    def madd(self,ins,in0,in1):
        match ins:
            case "MADD":
                add = in0 + in1
                cmp = np.where(add >= self.q, self.q, 0).astype(np.uint32)
                sub = add - cmp
                sft = sub
            case "ADD":
                add = in0 + in1
                cmp = 0
                sub = add - cmp
                sft = sub
            case "P2R":
                add = in0 + ((1<<(self.D-1)) - 1)
                cmp = 0
                sub = add - cmp
                sft = sub >> self.D
            case "DCP1":
                add = in0 + 127
                cmp = 0
                sub = add - cmp
                sft = sub >> 7
            case "DCP2"|"DCMP-1"|"DCMP-4"|"DCMP-5"|"DCMP-10"|"DCMP-11"|"CMP-1"|"CMP-4"|"CMP-5"|"CMP-10"|"CMP-11":
                add = in0 + 1
                cmp = 0
                sub = add - cmp
                sft = sub >> 1
            case "DCP3":
                add = in0
                cmp = np.where(add <= (self.q-1)//2, 1, 0).astype(np.uint32)
                eql = np.where(add == 0, 0, 1)
                sub = cmp & eql
                sft = sub
            case "MHINT":
                add = in0
                cmp_tmp = self.q-1-self.gamma2
                cmp = np.where(add <= cmp_tmp, 1, 0).astype(np.uint32) # <= q-1-gamma2
                eql = np.where(in1==0, 0, 1) # !=0
                sub = cmp | (eql<<1)
                sft = sub
            case "UHINT":
                add = in0
                cmp_tmp = self.alpha-1
                cmp = np.where(add >= 1, cmp_tmp, 1).astype(np.uint32) #in0 = a0_sign = 1 if a0>0
                sub = cmp
                sft = np.where(in1%2,cmp,0).astype(np.uint32) #in1 = hint
            case "CHKZ"|"CHKW0"|"CHKH":
                add = in0
                if("Z" in ins): cmp_tmp = self.gamma1 - self.beta
                elif("W0" in ins): cmp_tmp = self.gamma2 - self.beta
                else: cmp_tmp = self.gamma2
                cmp = np.where(add >= cmp_tmp, 1, 0).astype(np.uint32)
                sub = cmp
                sft = sub
        return sft
        
    # modular subtracter (1 pipeline stage)
    # (1 add, 1 cmp, 1 sub)
    def msub(self,ins,in0,in1):
        match ins:
            case "MSUB":
                sub = in0 - in1
                cmp = np.where(sub >= 2**31, self.q, 0).astype(np.uint32) # negative when >2^31 in np.uint32
                add = sub + cmp
            case "KMUL"|"KMAC":
                sub = in0 - self.q
                cmp = np.where(sub >= 2**31, self.q, 0).astype(np.uint32) # negative when >2^31 in np.uint32
                add = sub + cmp
            case "DCP2"|"CMP-1"|"CMP-4"|"CMP-5"|"CMP-10"|"CMP-11":
                if ins=="DCP2": sub_tmp = self.alpha
                else: sub_tmp = np.uint32(1<<int(ins.split("-")[-1])) # 2^d for d = 1/4/5/10/11
                sub = in0 - sub_tmp
                cmp = np.where(sub >= 2**31, sub_tmp, 0).astype(np.uint32)
                add = sub + cmp
            case "MHINT":
                sub = in0
                cmp = np.where(sub >= self.gamma2+1, 1, 0) # >= gamma2 + 1
                eql = np.where(sub == self.q-self.gamma2, 1, 0) # == q-gamma2
                add = cmp | (eql<<1)
            case "UHINT":
                sub = in0 - in1
                cmp = np.where(sub >= 2**31, self.alpha, 0).astype(np.uint32)
                add = sub + cmp
            case "CHKZ"|"CHKW0"|"CHKH":
                sub = in0
                if("Z" in ins): cmp_tmp = self.q - (self.gamma1 - self.beta)
                elif("W0" in ins): cmp_tmp = self.q - (self.gamma2 - self.beta)
                else: cmp_tmp = self.q - (self.gamma2)
                cmp = np.where(sub <= cmp_tmp, 1, 0).astype(np.uint32)
                add = cmp
        return add

    # modular multiplier
    # (1 duplex mul, 1 add, 1 red, 1 shift)
    def mmul(self,ins,in0,in1):
        match ins:
            case "MMUL":
                mul = in0.astype(np.uint64) * in1.astype(np.uint64)
                red = ((mul%self.q)*pow(self.R,-1,self.q)%self.q).astype(np.uint32)
                sft = red
            case "KMUL":
                # Multiplication of two polynomials of degree 1
                #duplex multiplication and addition
                mul = (in0 >> 12) * (in1 >> 12)  +  (in0 & 0xfff) * (in1 & 0xfff)
                red = ((mul%self.q)*pow(self.R,-1,self.q)%(2*self.q)).astype(np.uint32)
                # Note "red" != N2 in test_kem_red (test/red.py)
                # But "red" % q = N2 % q, so "red" used in here is only for simulating the range of N2 ([0,2*(q-1)^2))
                sft = red
            case "DCP2"|"DCMP-1"|"DCMP-4"|"DCMP-5"|"DCMP-10"|"DCMP-11"|"CMP-1"|"CMP-4"|"CMP-5"|"CMP-10"|"CMP-11":
                if ins == "DCP2": mul_tmp, sft_tmp = self.mulsft_table[ins][self.alpha]
                else: mul_tmp, sft_tmp = self.mulsft_table[ins]
                mul = in0.astype(np.uint64) * np.uint64(mul_tmp)
                red = mul
                sft = red >> sft_tmp
            case "DCP3":
                mul = in0 * (2*self.gamma2)
                red = mul
                sft = red
        return sft

    def exe(self, ins: str, data_in: np.ndarray):
        #self.check_input(ins, data_in)
        self.data_out = np.zeros((2,self.num), dtype=np.uint32) # output should be zeros if it is not used
        match ins: 
            case "MADD": 
                self.data_out[0] = self.madd("MADD",data_in[0],data_in[1])
            
            case "MSUB":
                self.data_out[0] = self.msub("MSUB",data_in[0],data_in[1])
            
            case "MMUL": 
                self.data_out[0] = self.mmul("MMUL",data_in[0],data_in[1])
            
            case "KMUL":
                tmp = self.mmul("KMUL",data_in[0],data_in[1]) # output in range [0,2q)
                self.data_out[0] = self.msub("KMUL",tmp,None) # -q if tmp>=q

            case "MMAC":
                tmp = self.mmul("MMUL",data_in[0],data_in[1])
                self.data_out[0] = self.madd("MADD",tmp,data_in[2])
            
            case "KMAC":
                tmp = self.mmul("KMUL",data_in[0],data_in[1]) # output in range [0,2q)
                tmp2 = self.msub("KMUL",tmp,None) # -q if tmp>=q
                self.data_out[0] = self.madd("MADD",tmp2,data_in[2])
            
            case "CT-BFO":
                tmp = self.mmul("MMUL",data_in[1],data_in[2])
                self.data_out[0] = self.madd("MADD",data_in[0],tmp)
                self.data_out[1] = self.msub("MSUB",data_in[0],tmp)
            
            case "GS-BFO":
                tmp0 = self.madd("MADD",data_in[0],data_in[1])
                tmp1 = self.msub("MSUB",data_in[0],data_in[1])
                self.data_out[0] = tmp0
                self.data_out[1] = self.mmul("MMUL",tmp1,data_in[2])

            # Power2Round
            # a1 = (a + (1 << (D-1)) - 1) >> D;
            # *a0 = a - (a1 << D);
            case "P2R":
                tmp0 = self.madd("P2R",data_in[0],None)
                tmp1 = self.msub("MSUB",data_in[0],tmp0<<self.D)
                self.data_out[0] = tmp1
                self.data_out[1] = tmp0
            
            # First stage of decompose
            # a1  = (a + 127) >> 7;
            case "DCP1":
                self.data_out[0] = self.madd("DCP1",data_in[0],None)
            
            # Second stage of decompose
            # if GAMMA2 == (Q-1)/32
            #   a1  = (a1*1025 + (1 << 21)) >> 22 = (((a1*1025) >> 21) + 1) >> 1
            #   a1 &= 15;
            # elif GAMMA2 == (Q-1)/88
            #   a1  = (a1*11275 + (1 << 23)) >> 24 = (((a1*11275) >> 23) + 1) >> 1
            #   a1 ^= ((43 - a1) >> 31) & a1;

            # Compression: round(input*2^d/q) mod 2^d
            # round(input*2^d/q) = (input * pre-computed factor + 2^(t-1))>>t for some t
            # = (((input * pre-computed factor) >> (t-1)) + 1) >> 1

            case "DCP2"|"CMP-1"|"CMP-4"|"CMP-5"|"CMP-10"|"CMP-11":
                tmp0 = self.mmul(ins,data_in[0],None)        # (input*1025>>21)
                tmp1 = self.madd(ins,tmp0,None)              # (input+1)>>1
                self.data_out[0] = self.msub(ins,tmp1,None)  # input%16

            # Third stage of decompose
            # *a0  = a - a1*2*GAMMA2; 
            # *a0 -= (((Q-1)/2 - *a0) >> 31) & Q;
            # For unsigned data format: a0' = (a-a1*2*GAMMA2) mod q
            # a0>0 iff  a0'<=(Q-1)/2 and a0'!=0
            case "DCP3":
                tmp0 = self.mmul("DCP3",data_in[1],None)
                tmp1 = self.msub("MSUB",data_in[0],tmp0)
                tmp2 = self.madd("DCP3",tmp1,None)
                self.data_out[0] = tmp1
                self.data_out[1] = tmp2

            # Makehint
            # a0 > GAMMA2 || a0 < -GAMMA2 || (a0 == -GAMMA2 and a1 != 0)
            # iff (GAMMA2+1 <= a0 <= q-1-GAMMA2) || (a0 == q-GAMMA2 and a1 != 0)
            case "MHINT":
                tmp0 = self.msub("MHINT",data_in[0],None) #[1:0] = (a0==q-GAMMA2) | (a0>=GAMMA2+1)
                tmp1 = self.madd("MHINT",data_in[0],data_in[1]) #[1:0] = (a1 != 0) | (a0 <= q-1-GAMMA2)
                self.data_out[0] = ((tmp0>>1)&(tmp1>>1)) | ((tmp0%2)&(tmp1%2))

            # Usehint
            # a1 = decompose(&a0, a); (performed by DECOMP1-3)
            # if(hint == 0)
            #    return a1;
            # if GAMMA2 == (Q-1)/32
            #   if(a0 > 0)
            #       return (a1 + 1) & 15;
            #   else
            #       return (a1 - 1) & 15;
            # elif GAMMA2 == (Q-1)/88
            #   if(a0 > 0)
            #       return (a1 == 43) ?  0 : a1 + 1;
            #   else
            #       return (a1 ==  0) ? 43 : a1 - 1;

            #  the above prcoess is equivalent to the following
            #  tmp = 0 (hint==0) or -1 (a0>0) or 1 (a0<=0) (by MADD)
            #  output = (a1 - tmp) mod (16/44) (by MSUB)
            case "UHINT":
                #data_in = a0_sign, a1, hint
                tmp0 = self.madd("UHINT",data_in[0],data_in[2])
                self.data_out[0] = self.msub("UHINT",data_in[1],tmp0)

            # chknorm
            # |input| >= bound
            # iff bound <= input <= q-bound
            # bound = gamma1-beta (CHKZ) or gamma2-beta (CHKW0) or gamma2 (CHKH)
            case "CHKZ"|"CHKW0"|"CHKH":
                tmp0 = self.madd(ins,data_in[0],None)  # >= bound
                tmp1 = self.msub(ins,data_in[0],None)  # <= q-bound
                self.data_out[0] = tmp0 & tmp1

            # Decompression: round(input*q/2^d) = (input * q + 2^(d-1)) >> d
            # = (((input * q) >> (d-1) + 1) >> 1 
            case "DCMP-1"|"DCMP-4"|"DCMP-5"|"DCMP-10"|"DCMP-11":
                tmp0 = self.mmul(ins,data_in[0],None)        # (input*constant A>>constant B)
                self.data_out[0] = self.madd(ins,tmp0,None)  # (input+1)>>1
            
            
        return self.data_out
        

    
