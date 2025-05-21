

class PE:
    # Constants for the different security levels
    DILITHIUM_or_KYBER = 0 # 0 for DILITHIUM, 1 for KYBER
    security_level = 0 # 0 for low, 1 for medium, 2 for high

    KYBER_Q = 3329
    DILITHIUM_Q = 8380417
    Q = [DILITHIUM_Q, KYBER_Q]
    DILITHIUM_GAMMA2 = [(DILITHIUM_Q-1) // 88,(DILITHIUM_Q-1) // 32,(DILITHIUM_Q-1) // 32]




    def __init__(self, DILITHIUM_or_KYBER, security_level):
        # Initialize any necessary state or variables
        self.security_level = security_level
        self.DILITHIUM_or_KYBER = DILITHIUM_or_KYBER
        
        return
    def change_mode(self, DILITHIUM_or_KYBER, security_level):
        self.security_level = security_level
        self.DILITHIUM_or_KYBER = DILITHIUM_or_KYBER
        return 0
    # Basic arithmetic operations
    def add(self, a, b):
        return a + b

    def subtract(self, a, b):
        return a - b

    def multiply(self, a, b):
        return a * b
    
    def greater_than(self, a, b):
        return a > b


    # Modular arithmetic operations
    def mod_add(self, a, b, mod):
        return (a + b) % mod

    def mod_subtract(self, a, b, mod):
        return (a - b) % mod

    def mod_multiply(self, a, b, mod):
        return (a * b) % mod
    def montgomery_reduce(self, a, mod):
        return a % mod

    def decompose(self, a):
        ################### cycle 1 ###################

        # a1 = (a + 127) >> 7
        a1 = self.add(a,127) >> 7
        if self.security_level == 0:
            # a1 = (a1 * 11275 + (1 << 23)) >> 24
            a1 = (self.subtract(self.multiply(a1,11275), -(1 << 23))) >> 24

            a1 = 0 if a1 == 44 else a1
        else:
            # a1 = (a1 * 1025 + (1 << 21)) >> 22
            a1 = (self.subtract(self.multiply(a1,1025), -(1 << 21))) >> 22
            
            a1 &= 15

        ################### cycle 2 ###################
        
        # a0 = a - a1 * 2 * self.DILITHIUM_GAMMA2[self.security_level]
        a0 = self.subtract(a, self.multiply(a1, 2*self.DILITHIUM_GAMMA2[self.security_level]))  

        # a0 -= (((self.Q - 1) // 2 - a0) >> 31) & self.Q 
        sign = self.greater_than(a0, (self.Q[self.DILITHIUM_or_KYBER] - 1) // 2)
        if sign:
            a0 = self.add(a0, - self.Q[self.DILITHIUM_or_KYBER])
            
        return a1, a0


