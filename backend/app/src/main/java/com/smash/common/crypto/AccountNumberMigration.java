package com.smash.common.crypto;

import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.boot.ApplicationArguments;
import org.springframework.boot.ApplicationRunner;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.stereotype.Component;

import java.util.List;
import java.util.Map;
import java.util.Objects;

@Slf4j
@Component
@RequiredArgsConstructor
public class AccountNumberMigration implements ApplicationRunner {

    private final JdbcTemplate jdbcTemplate;

    @Override
    public void run(ApplicationArguments args) {
        try {
            List<Map<String, Object>> rows = jdbcTemplate.queryForList(
                    "SELECT id, account_number FROM taxi_settlement "
                            + "WHERE account_number IS NOT NULL AND account_number NOT LIKE 'enc:%'"
            );

            for (Map<String, Object> row : rows) {
                String plain = (String) row.get("account_number");
                jdbcTemplate.update(
                        "UPDATE taxi_settlement SET account_number = ? WHERE id = ?",
                        FieldCrypto.encrypt(plain), row.get("id")
                );
            }

            if (!rows.isEmpty()) {
                log.info("계좌번호 {}건을 암호화했습니다.", rows.size());
            }
        } catch (Exception e) {
            // 이전 실패가 서버 시작을 막지 않도록 기록만 남김 (평문 행은 그대로 읽을 수 있음)
            log.error("계좌번호 암호화 이전에 실패했습니다.", e);
        }
    }
}
