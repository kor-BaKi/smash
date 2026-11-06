package com.smash.common.crypto;

import jakarta.persistence.AttributeConverter;
import jakarta.persistence.Converter;

// 엔티티의 계좌번호(평문)를 DB에 저장할 때 암호화하고, 읽을 때 복호화한다.
@Converter
public class AccountNumberConverter implements AttributeConverter<String, String> {
    @Override
    public String convertToDatabaseColumn(String attribute) {
        return attribute == null ? null : FieldCrypto.encrypt(attribute);
    }

    @Override
    public String convertToEntityAttribute(String dbData) {
        return dbData == null ? null : FieldCrypto.decrypt(dbData);
    }
}
