package com.smash.common.crypto;

import javax.crypto.Cipher;
import javax.crypto.spec.GCMParameterSpec;
import javax.crypto.spec.SecretKeySpec;
import java.nio.ByteBuffer;
import java.nio.charset.StandardCharsets;
import java.security.GeneralSecurityException;
import java.security.SecureRandom;
import java.util.Base64;

// 민감한 문자열 필드(계좌번호 등)를 AES-256-GCM으로 암/복호화
// 저장 형식 : "enc:" + base64(IV 12바이트 + 암호문 + 인증 태그)
public class FieldCrypto {

    private static final String PREFIX = "enc:";
    private static final int IV_LENGTH = 12;
    private static final int TAG_BITS = 128;
    private static final SecureRandom RANDOM = new SecureRandom();

    private static volatile SecretKeySpec key;

    private FieldCrypto() {
    }

    // base64로 인코딩된 32바이트 키로 초기화
    public static void init(String base64Key) {
        byte[] bytes = Base64.getDecoder().decode(base64Key.trim());
        if (bytes.length != 32) {
            throw new IllegalArgumentException("암호화 키는 32바이트(base64)여야 합니다.");
        }
        key = new SecretKeySpec(bytes, "AES");
    }

    public static boolean isEncrypted(String value) {
        return value != null && value.startsWith(PREFIX);
    }

    public static String encrypt(String plain) {
        SecretKeySpec k = requireKey();
        try {
            byte[] iv = new byte[IV_LENGTH];
            RANDOM.nextBytes(iv);

            Cipher cipher = Cipher.getInstance("AES/GCM/NoPadding");
            cipher.init(Cipher.ENCRYPT_MODE, k, new GCMParameterSpec(TAG_BITS, iv));
            byte[] encrypted = cipher.doFinal(plain.getBytes(StandardCharsets.UTF_8));

            byte[] packed = ByteBuffer.allocate(iv.length + encrypted.length)
                    .put(iv)
                    .put(encrypted)
                    .array();
            return PREFIX + Base64.getEncoder().encodeToString(packed);
        } catch (GeneralSecurityException e) {
            throw new IllegalStateException("암호화에 실패했습니다.", e);
        }
    }

    // "enc:"로 시작하지 않는 값은 암호화 도입 전의 평문이므로 그대로 돌려준다.
    public static String decrypt(String stored) {
        if (!isEncrypted(stored)) {
            return stored;
        }
        SecretKeySpec k = requireKey();
        try {
            byte[] packed = Base64.getDecoder().decode(stored.substring(PREFIX.length()));
            Cipher cipher = Cipher.getInstance("AES/GCM/NoPadding");
            cipher.init(Cipher.DECRYPT_MODE, k, new GCMParameterSpec(TAG_BITS, packed, 0, IV_LENGTH));
            byte[] plain = cipher.doFinal(packed, IV_LENGTH, packed.length - IV_LENGTH);
            return new String(plain, StandardCharsets.UTF_8);
        } catch (GeneralSecurityException e) {
            throw new IllegalStateException("복호화에 실패했습니다.", e);
        }
    }

    private static SecretKeySpec requireKey() {
        SecretKeySpec k = key;
        if (k == null) {
            throw new IllegalStateException("암호화 키가 초기화되지 않았습니다.");
        }
        return k;
    }
}
