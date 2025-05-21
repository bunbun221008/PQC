import sys
import os
src_path = os.path.abspath(os.path.join(os.path.dirname(__file__), '../src'))
if src_path not in sys.path:
    sys.path.append(src_path)
import pe_array
import numpy as np
def power2round(a): #Algortihm 35 in FIPS 204
    q = 8380417
    D = 13
    tmp = a%np.power(2,D)
    a0 = np.where(tmp>np.power(2,D-1), tmp-np.power(2,D), tmp)
    a1 = (a-a0)>>D
    a0 = a0 % q
    return a0, a1

def decompose(a,gamma2): #Algortihm 36 in FIPS 204 (adding a0_sign for debug)
    q = 8380417
    a0 = a%(2*gamma2)
    a0 = np.where(a0>gamma2,a0-2*gamma2,a0)
    tmp = a-a0
    a1 = np.where(tmp==(q-1),0,tmp//(2*gamma2))
    a0 = np.where(tmp==(q-1),(a0-1),a0)
    a0_sign = np.where(a0>0,1,0)
    a0 = a0%q
    return a0, a0_sign, a1

def makehint(a0,a1,gamma2): # "make_hint" function in reference c code
    q = 8380417
    tmp = np.where(a0>(q//2),a0-q,a0)
    return np.where((tmp>gamma2)|(tmp<-gamma2)|((tmp==-gamma2)&(a1!=0)),1,0)

def usehint(a,h,gamma2): # "use_hint" function in reference c code
    q = 8380417
    a0, a0_sign, a1 = decompose(a,gamma2)
    if(gamma2==(q-1)//32):
        rst = np.where(h==0,a1,np.where(a0_sign>0,(a1+1)%16,(a1-1)%16))
    elif(gamma2==(q-1)//88):
        rst = np.where(h==0,a1,np.where(a0_sign>0,(a1+1)%44,(a1-1)%44))
    return rst

def test_pe(pe_num,alg,ins,test_coeffs,test_all_num_within_q=False):
    PA = pe_array.pe_array(pe_num)
    PA.reset(alg)
    if test_all_num_within_q:
        test_loop = int(np.ceil(PA.q/pe_num))
    else:
        if test_coeffs%pe_num!=0:
            raise ValueError("test_coeffs needed to be multiple of test_coeffs")
        test_loop = test_coeffs//pe_num
    
    print("Testing "+str(alg)+": "+str(ins))

    for i in range(test_loop):
        if test_all_num_within_q:
            data = np.array([[(i*pe_num+j)%PA.q for j in range(pe_num)] for k in range(3)])
            #print("finish {:.2f} %".format((i+1)*100/test_loop))
        else:
            data = np.random.randint(PA.q,size=(3,pe_num))
        
        match ins:
            case "MADD":
                if np.any((data[0]+data[1])%PA.q != PA.exe("MADD",data.astype(np.uint32))[0]):
                    raise ValueError("MADD Fail")

            case "MSUB":
                if np.any((data[0]-data[1])%PA.q != PA.exe("MSUB",data.astype(np.uint32))[0]):
                    print((data[0]-data[1])%PA.q,PA.exe("MSUB",data.astype(np.uint32))[0])
                    raise ValueError("MSUB Fail")

            case "MMUL":
                ans = (data[0]*data[1])%PA.q
                ans = (ans*pow(PA.R,-1,PA.q))%PA.q
                rst = PA.exe("MMUL",data.astype(np.uint32))[0]
                if np.any(ans != rst):
                    raise ValueError("MMUL Fail")

            case "KMUL":
                ans = ((data[0]>>12)*(data[1]>>12)+(data[0]&0xfff)*(data[1]&0xfff))%PA.q
                ans = (ans*pow(PA.R,-1,PA.q))%PA.q
                rst = PA.exe("KMUL",data.astype(np.uint32))[0]
                if np.any(ans!=rst):
                    raise ValueError("KMUL Fail")
            
            case "MMAC":
                ans = (data[0]*data[1])%PA.q
                ans = (ans*pow(PA.R,-1,PA.q))%PA.q
                ans = (ans + data[2])%PA.q
                rst = PA.exe("MMAC",data.astype(np.uint32))[0]
                if np.any(ans!=rst):
                    raise ValueError("MMAC Fail")
            
            case "KMAC":
                ans = ((data[0]>>12)*(data[1]>>12)+(data[0]&0xfff)*(data[1]&0xfff))%PA.q
                ans = (ans*pow(PA.R,-1,PA.q))%PA.q
                ans = (ans + data[2])%PA.q
                rst = PA.exe("KMAC",data.astype(np.uint32))[0]
                if np.any(ans!=rst):
                    raise ValueError("KMAC Fail")
            
            case "CT-BFO":
                tmp = (data[1]*data[2])%PA.q
                tmp = (tmp*pow(PA.R,-1,PA.q))%PA.q
                ans0, ans1 = (data[0]+tmp)%PA.q, (data[0]-tmp)%PA.q
                rst0, rst1 = PA.exe("CT-BFO",data.astype(np.uint32))[0:2]
                if np.any(ans0!=rst0) or np.any(ans1!=rst1):
                    raise ValueError("CT-BFO Fail")

            case "GS-BFO":
                ans1 = ((data[0]-data[1])*data[2])%PA.q
                ans1 = (ans1*pow(PA.R,-1,PA.q))%PA.q
                ans0 = (data[0]+data[1])%PA.q
                rst0, rst1 = PA.exe("GS-BFO",data.astype(np.uint32))[0:2]
                if np.any(ans0!=rst0) or np.any(ans1!=rst1):
                    print(ans1,rst1)
                    raise ValueError("GS-BFO Fail")

            case "P2R":
                ans0, ans1 = power2round(data[0])
                rst0, rst1 = PA.exe("P2R",data.astype(np.uint32))[0:2]
                if np.any(ans0!=rst0) or np.any(ans1!=rst1):
                    raise ValueError("P2R Fail")
            
            case "DCP":
                ans0, ans0_sign, ans1 = decompose(data[0],PA.gamma2)
                rst1 = PA.exe("DCP1",data.astype(np.uint32))[0]
                rst1 = PA.exe("DCP2",np.vstack((rst1,data[1:3])).astype(np.uint32))[0]
                rst0, rst0_sign = PA.exe("DCP3",np.vstack((data[0],rst1,data[2])).astype(np.uint32))[0:2]
                if np.any(ans0!=rst0) or np.any(ans0_sign!=rst0_sign) or np.any(ans1!=rst1):
                    raise ValueError("DSA DCP1-3 Fail with gamma2 = (q-1)//"+str((PA.q-1)//PA.gamma2))

            case "MHINT":
                ans = makehint(data[0],data[1],PA.gamma2)
                rst = PA.exe("MHINT",data.astype(np.uint32))[0]
                if np.any(ans!=rst):
                    raise ValueError("DSA MHINT Fail with gamma2 = (q-1)//"+str((PA.q-1)//PA.gamma2))
            
            case "UHINT":
                hint = data[1]%2
                ans = usehint(data[0],hint,PA.gamma2)
                rst1 = PA.exe("DCP1",data.astype(np.uint32))[0]
                rst1 = PA.exe("DCP2",np.vstack((rst1,data[1:3])).astype(np.uint32))[0]
                rst0, rst0_sign = PA.exe("DCP3",np.vstack((data[0],rst1,data[2])).astype(np.uint32))[0:2]
                rst = PA.exe("UHINT",np.vstack((rst0_sign,rst1,hint)).astype(np.uint32))[0]
                if np.any(ans!=rst):
                    raise ValueError("DSA UHINT Fail with gamma2 = (q-1)//"+str((PA.q-1)//PA.gamma2))

            case "CHKZ":
                ans = (data[0] >= (PA.gamma1 - PA.beta)) &  (data[0] <= PA.q - (PA.gamma1 - PA.beta))
                rst = PA.exe("CHKZ",data.astype(np.uint32))[0]
                if np.any(ans!=rst):
                    raise ValueError("CHKZ Fail with alg = "+str(alg))

            case "CHKW0":
                ans = (data[0] >= (PA.gamma2 - PA.beta)) &  (data[0] <= PA.q - (PA.gamma2 - PA.beta))
                rst = PA.exe("CHKW0",data.astype(np.uint32))[0]
                if np.any(ans!=rst):
                    raise ValueError("CHKW0 Fail with alg = "+str(alg))
            
            case "CHKH":
                ans = (data[0] >= (PA.gamma2)) &  (data[0] <= PA.q - (PA.gamma2))
                rst = PA.exe("CHKH",data.astype(np.uint32))[0]
                if np.any(ans!=rst):
                    raise ValueError("CHKH Fail with alg = "+str(alg))
            
            case "DCMP-1"|"DCMP-4"|"DCMP-5"|"DCMP-10"|"DCMP-11":
                tmp = int(ins.split("-")[-1]) # 1/4/5/10/11
                ans = ((data[0]*PA.q)+(1<<(tmp-1)))>>tmp
                rst = PA.exe(ins,data.astype(np.uint32))[0]
                if np.any(ans!=rst):
                    raise ValueError(str(ins)+" Fail with alg = "+str(alg))

            case "CMP-1"|"CMP-4"|"CMP-5"|"CMP-10"|"CMP-11":
                tmp = int(ins.split("-")[-1]) # 1/4/5/10/11
                rst = PA.exe(ins,data.astype(np.uint32))[0]
                ans = np.round((data[0].astype(np.float64)*(1<<tmp))/PA.q).astype(np.uint32)%(1<<tmp)
                if np.any(ans!=rst):
                    raise ValueError(str(ins)+" Fail with alg = "+str(alg))
    
if __name__ == "__main__":
    np.random.seed(0)
    pe_num = 4
    test_coeffs = 10000
    test_all_num_within_q = False
    for alg in ["DSA-44","KEM-512"]:
        for ins in ["MADD","MSUB","CT-BFO","GS-BFO","MMUL","MMAC"]:
            test_pe(pe_num,alg,ins,test_coeffs,False)
    for ins in ["KMUL","KMAC"]:
        test_pe(pe_num,"KEM-512",ins,test_coeffs,False)
    test_pe(pe_num,"DSA-44","P2R",test_coeffs,False)
    for alg in ["DSA-44","DSA-65"]:
        for ins in ["DCP","MHINT","UHINT"]:
            test_pe(pe_num,alg,ins,test_coeffs,False)
    for alg in ["DSA-44","DSA-65","DSA-87"]:
        for ins in ["CHKZ","CHKW0","CHKH"]:
            test_pe(pe_num,alg,ins,test_coeffs,False)
    for ins in ["DCMP-1","DCMP-4","DCMP-5","DCMP-10","DCMP-11","CMP-1","CMP-4","CMP-5","CMP-10","CMP-11"]:
        test_pe(pe_num,"KEM-512",ins,test_coeffs,True)