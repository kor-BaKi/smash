package com.smash.common.crypto;



import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Component;

// 서버 시작 시 설정에서 암호화 키를 읽어 FieldCrypto를 초기화
// 키가 없거나 형식이 틀리면 서버가 시작되지 않는다. (평문 저장 사고 방지)
@Component
public class FieldCryptoInitializer {

    public FieldCryptoInitializer(@Value("${app.crypto.key}") String base64Key) {
        FieldCrypto.init(base64Key);
    }
}
