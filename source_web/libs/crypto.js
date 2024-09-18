const PUBLIC_KEY = `
MIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEAmO8Jj6+2IgYHgT7UIybp
iBVdqGUV7h5m1zrDm5y9Cs94Bgy6yulgjQ8dOW88VVdCsZQfFhLqdllMq0rylOx4
bAOW9PdDwmV5npAbM1N7bBmdSnCIfPobpRF4VS+QC3QNYO4dAbqVbadaqL1NWhxp
0oO3A3XS3D1XO6Hj26K3WvSrFlQ32K+QkFlb9E9k5REAyiOkbPhTqNnvv/9fdVMr
fIDasxz92pFvWUR2HowX2i1O8QUUD6530skFyvJ3IgBUfKdSVR/FPrR90q3Tci7T
hX4zW4VqmRJHqRrPRiXGLfPUOjthGWt4ev8ogRliO6QNxgLmXOmuwq3FlJ4sXEn7
xQIDAQAB
`;
const PUBLIC_KEY_LIB = await window.crypto.subtle.importKey(
    "spki",
    new Uint8Array([...window.atob(PUBLIC_KEY.replace(/(-----(BEGIN|END) PUBLIC KEY-----|\s)/g, ''))].map(char => char.charCodeAt(0))),
    {
        name: "RSA-OAEP",
        hash: "SHA-256"
    },
    true,
    ["encrypt"]
);

async function encryptText(text) {
    const encoder = new TextEncoder();
    const encodedText = encoder.encode(text);

    const encrypted = await window.crypto.subtle.encrypt(
        {
            name: "RSA-OAEP"
        },
        PUBLIC_KEY_LIB,
        encodedText
    );

    // Converter para Base64 para enviar em um formato amigável
    const encryptedArray = Array.from(new Uint8Array(encrypted));
    const encryptedBase64 = btoa(String.fromCharCode(...encryptedArray));

    return encryptedBase64;
}

export default encryptText;

