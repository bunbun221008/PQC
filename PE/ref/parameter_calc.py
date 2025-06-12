


Q = 8380417
D = 13
Alpha = 16 
Beta = 120 
Gamma1 = 1<<19 
Gamma2 = 261888 

D_sub1_ls1_sub1 = (1 << (D - 1)) - 1
Q_sub1_rs1 = (Q - 1) >> 1
Q_sub1_subGamma2 = Q - 1 - Gamma2
Gamma1_subBeta = Gamma1 - Beta
Alpha_sub1 = Alpha - 1
Gamma2_add1 = Gamma2 + 1
Q_subGamma2 = (Q-Gamma2)
Q_subGamma1_addBeta = Q - (Gamma1 - Beta)
Q_subGamma2_addBeta = Q - (Gamma2 - Beta)
Alpha_eql16_1025or11275 = 1025 if(Alpha == 16) else 11275
Alpha_eql16_21or23 = 21 if(Alpha == 16) else 23 

print("Q = ", Q)
print("D = ", D)
print("Alpha = ", Alpha)
print("Beta = ", Beta)
print("Gamma1 = ", Gamma1)
print("Gamma2 = ", Gamma2)
print("D_sub1_ls1_sub1 = ", D_sub1_ls1_sub1)
print("Q_sub1_rs1 = ", Q_sub1_rs1)
print("Q_sub1_subGamma2 = ", Q_sub1_subGamma2)
print("Gamma1_subBeta = ", Gamma1_subBeta)
print("Alpha_sub1 = ", Alpha_sub1)
print("Gamma2_add1 = ", Gamma2_add1)
print("Q_subGamma2 = ", Q_subGamma2)
print("Q_subGamma1_addBeta = ", Q_subGamma1_addBeta)
print("Q_subGamma2_addBeta = ", Q_subGamma2_addBeta)
print("Alpha_eql16_1025or11275 = ", Alpha_eql16_1025or11275)
print("Alpha_eql16_21or23 = ", Alpha_eql16_21or23)
# This code calculates and prints various parameters used in the PE (Processing Element) design for cryptographic algorithms.