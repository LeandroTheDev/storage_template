const JSEncrypt = require('node-jsencrypt');

const PRIVATE_KEY = `
-----BEGIN RSA PRIVATE KEY-----
MIIEowIBAAKCAQEAmO8Jj6+2IgYHgT7UIybpiBVdqGUV7h5m1zrDm5y9Cs94Bgy6
yulgjQ8dOW88VVdCsZQfFhLqdllMq0rylOx4bAOW9PdDwmV5npAbM1N7bBmdSnCI
fPobpRF4VS+QC3QNYO4dAbqVbadaqL1NWhxp0oO3A3XS3D1XO6Hj26K3WvSrFlQ3
2K+QkFlb9E9k5REAyiOkbPhTqNnvv/9fdVMrfIDasxz92pFvWUR2HowX2i1O8QUU
D6530skFyvJ3IgBUfKdSVR/FPrR90q3Tci7ThX4zW4VqmRJHqRrPRiXGLfPUOjth
GWt4ev8ogRliO6QNxgLmXOmuwq3FlJ4sXEn7xQIDAQABAoIBAHWCrtEWTZeFFH0t
/qjn/GdRK3759UjbWWAlyimm3OcSlYHohBroCgU5SNZZ730PqLJ0QxKeBERdx3iT
BSSDMuCkPXkLCai0eifpSM0+Z0afw+lv4KBPObCzZMfn3QG/8Yu6StWKPclc319q
3aXQ0UstZBGnlhcelwm+EiwwsjyTNTD+Xx3nwc3yB2Dxr0SzScGdttQFxXW3vg1E
dbdDwN7L9CziBnTUv933mlzh92Q5g/tp3Ln6kpDokapQ9s9PLHP/plw5yM8d7Cx/
UaairLJEe7bDbFzgdfm5jTVP+MbqvFP6ghIQORqX9wd417cfCDC4IzrA48u6R0z7
eCU9wgECgYEAy9ijyf8R4d7uxPH18b1tY1kb7iV1PScOECk/LdsOKYUBelmlpFIj
Tz+MR7iBv43++kC+GVTC3sMEIoUANVjDMB+qKGPjsc9Nad2jpFLHwiNGffxtlwSy
nQBF3YgIoferbXbwOklLxlu5OO9ClYXY/qBYPv5v9RdaVL5ETH2WdoECgYEAwA/F
M1cffwed0RNLBrpJLb98CPjhH7DXBeuA7qggFtKKOaIBKX9tB2KL0wLxLyyuzhpe
rc3r8iaqV8WdfuqNa4TZhndh9u5s5wPfG+6SbiGKtc6x5HyIMyK4l8RR81Pl2kQa
8U8nZEQlGiNtQYYMYMmekz5DuTAwKOQ0kIZki0UCgYByrjCHRa7Dye2+cvmQxKcz
y0ABXKV2f/BTe0EGBUUUarWIJcMgjO08el3rQ4wLPlGCbMYF7j+rnz9GRFj3qjY1
brsF+hxxPlUpB/42RjQHrlzMKCVnXsc1uJ+VoCBrLrEM5msD/5RXxeaQd1qYUDLi
HUdIOVC3LCovntNBzS3HAQKBgDaKg/LPc/dL/2onM3AmqK9gKGYX3z5zpqxcs5GS
lwJEKdKyCehx8lFdj92NgVZnNwD6hhaPWsi6aDdivBYVn7F/2ZIRBvXrwWtdMxeo
iVbTGaQFnYkIQFldK9SVgLw8ABMashgC5WnY3DxvARDRc2Rs/SZNUUgewh5qp+6+
64CNAoGBAIf0qqps1ApZypE+iea/csKlJNJB95wlK9Yc6K3fuBnNIkew1+aNaiVQ
6nepHLXbJlttieJRRglAzLViRzvWELRwzAs80a07g2ZaMHvBTscPYQ64+mepdDjj
6B40FblODrukSMZjorStoCLxQhZ1fNLY9Ln+CJ5PfHexkukRyKSg
-----END RSA PRIVATE KEY-----
`;

/// Decrypt the text by the private key provided
function decryptText(encryptedText) {
    try {
        const decryptor = new JSEncrypt();
        decryptor.setPrivateKey(PRIVATE_KEY);

        // Descriptografando a mensagem
        return decryptor.decrypt(encryptedText);
    } catch (error) {
        return "Decrypt Error";
    }
}

module.exports = decryptText;
