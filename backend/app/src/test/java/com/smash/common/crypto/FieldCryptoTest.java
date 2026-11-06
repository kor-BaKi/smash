package com.smash.common.crypto;

import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;

import java.util.Base64;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.catchThrowable;


public class FieldCryptoTest {

    private static String keyOf(int seed) {
        byte[] bytes = new byte[32];
        for (int i = 0; i < bytes.length; i++) {
            bytes[i] = (byte) (seed + i);
        }
        return Base64.getEncoder().encodeToString(bytes);
    }

    @BeforeEach
    void setUp() {
        FieldCrypto.init(keyOf(1));
    }

    @Test
    @DisplayName("암호화한 값을 복호화하면 원래 값이 나온다.")
    void roundTrip() {
        String encrypted = FieldCrypto.encrypt("110-1234-5678-90");

        assertThat(FieldCrypto.decrypt(encrypted)).isEqualTo("110-1234-5678-90");
    }

    @Test
    @DisplayName("암호문은 접두사가 붙고 평문이 그대로 들어 있지 않다")
    void ciphertextHidesPlaintext() {
        String encrypted = FieldCrypto.encrypt("110123456789");

        assertThat(FieldCrypto.isEncrypted(encrypted)).isTrue();
        assertThat(encrypted).doesNotContain("110123456789");
    }

    @Test
    @DisplayName("같은 값도 암호화할 때마다 다른 암호문이 된다 (IV 무작위)")
    void differentCiphertextEachTime() {
        String first = FieldCrypto.encrypt("110123456789");
        String second = FieldCrypto.encrypt("110123456789");

        assertThat(first).isNotEqualTo(second);
        assertThat(FieldCrypto.decrypt(first)).isEqualTo(FieldCrypto.decrypt(second));
    }

    @Test
    @DisplayName("접두사가 없는 기존 평문은 복호화 시 그대로 반환된다 (이전 호환)")
    void legacyPlaintextPassesThrough() {
        assertThat(FieldCrypto.decrypt("110123456789")).isEqualTo("110123456789");
    }

    @Test
    @DisplayName("암호문이 변조되면 복호화에 실패한다")
    void tamperedCiphertextRejected() {
        String encrypted = FieldCrypto.encrypt("110123456789");
        StringBuilder tampered = new StringBuilder(encrypted);
        int index = "enc:".length() + 10;
        tampered.setCharAt(index, tampered.charAt(index) == 'A' ? 'B' : 'A');

        Throwable thrown = catchThrowable(() -> FieldCrypto.decrypt(tampered.toString()));

        assertThat(thrown).isInstanceOf(IllegalStateException.class);
    }

    @Test
    @DisplayName("다른 키로는 복호화할 수 없다")
    void wrongKeyRejected() {
        String encrypted = FieldCrypto.encrypt("110123456789");
        FieldCrypto.init(keyOf(50));

        Throwable thrown = catchThrowable(() -> FieldCrypto.decrypt(encrypted));

        assertThat(thrown).isInstanceOf(IllegalStateException.class);
    }

    @Test
    @DisplayName("키 길이가 32바이트가 아니면 초기화에 실패한다")
    void invalidKeyLengthRejected() {
        String shortKey = Base64.getEncoder().encodeToString(new byte[16]);

        Throwable thrown = catchThrowable(() -> FieldCrypto.init(shortKey));

        assertThat(thrown).isInstanceOf(IllegalArgumentException.class);
    }

    @Test
    @DisplayName("변환기: null은 그대로, 값은 암호화되어 저장되고 복호화되어 읽힌다")
    void converterHandlesNullAndValue() {
        AccountNumberConverter converter = new AccountNumberConverter();

        assertThat(converter.convertToDatabaseColumn(null)).isNull();
        assertThat(converter.convertToEntityAttribute(null)).isNull();

        String stored = converter.convertToDatabaseColumn("110123456789");
        assertThat(stored).startsWith("enc:");
        assertThat(converter.convertToEntityAttribute(stored)).isEqualTo("110123456789");
    }
}