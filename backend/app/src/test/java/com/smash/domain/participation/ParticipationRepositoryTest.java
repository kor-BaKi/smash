package com.smash.domain.participation;

import com.smash.domain.activity.Activity;
import com.smash.domain.activity.ActivityType;
import com.smash.domain.activity.ActivityRepository;
import com.smash.domain.activity.CreatedBy;
import com.smash.domain.group.DayOfWeek;
import com.smash.domain.group.Group;
import com.smash.domain.group.GroupRepository;
import com.smash.domain.group.TimeSlot;
import com.smash.domain.user.Role;
import com.smash.domain.user.Status;
import com.smash.domain.user.User;
import com.smash.domain.user.UserRepository;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.jdbc.AutoConfigureTestDatabase;
import org.springframework.boot.test.autoconfigure.orm.jpa.DataJpaTest;

import java.time.LocalDate;
import java.util.List;

import static org.assertj.core.api.Assertions.assertThat;

@DataJpaTest
@AutoConfigureTestDatabase(replace = AutoConfigureTestDatabase.Replace.ANY)
class ParticipationRepositoryTest {

    @Autowired ParticipationRepository participationRepository;
    @Autowired ActivityRepository activityRepository;
    @Autowired GroupRepository groupRepository;
    @Autowired UserRepository userRepository;

    private User user;
    private Activity activity1;
    private Activity activity2;
    private Activity activity3;

    @BeforeEach
    void setUp() {
        Group group = groupRepository.save(Group.builder()
                .dayOfWeek(DayOfWeek.MON)
                .timeSlot(TimeSlot.SLOT_13_15)
                .build());

        user = userRepository.save(User.builder()
                .name("테스터")
                .studentNo("20250001")
                .password("password")
                .role(Role.MEMBER)
                .status(Status.ACTIVE)
                .build());

        activity1 = activityRepository.save(Activity.builder()
                .group(group)
                .activityDate(LocalDate.of(2026, 7, 1))
                .activityType(ActivityType.REGULAR)
                .createdBy(CreatedBy.AUTO)
                .build());

        activity2 = activityRepository.save(Activity.builder()
                .group(group)
                .activityDate(LocalDate.of(2026, 7, 2))
                .activityType(ActivityType.REGULAR)
                .createdBy(CreatedBy.AUTO)
                .build());

        activity3 = activityRepository.save(Activity.builder()
                .group(group)
                .activityDate(LocalDate.of(2026, 7, 3))
                .activityType(ActivityType.REGULAR)
                .createdBy(CreatedBy.AUTO)
                .build());
    }

    @Test
    @DisplayName("IN 쿼리로 여러 활동의 participation을 한 번에 조회한다")
    void findByActivityIdInAndUserId_returnsAllMatchingParticipations() {
        // given
        participationRepository.save(Participation.builder()
                .activity(activity1).user(user).type(ParticipationType.REGULAR).build());
        participationRepository.save(Participation.builder()
                .activity(activity2).user(user).type(ParticipationType.ABSENT).build());
        // activity3은 participation 없음

        // when
        List<Long> activityIds = List.of(activity1.getId(), activity2.getId(), activity3.getId());
        List<Participation> result = participationRepository
                .findByActivityIdInAndUserId(activityIds, user.getId());

        // then
        assertThat(result).hasSize(2);
        assertThat(result).extracting(p -> p.getActivity().getId())
                .containsExactlyInAnyOrder(activity1.getId(), activity2.getId());
    }

    @Test
    @DisplayName("participation이 없는 활동은 결과에 포함되지 않는다")
    void findByActivityIdInAndUserId_noParticipation_returnsEmpty() {
        // given — participation 없음

        // when
        List<Long> activityIds = List.of(activity1.getId(), activity2.getId());
        List<Participation> result = participationRepository
                .findByActivityIdInAndUserId(activityIds, user.getId());

        // then
        assertThat(result).isEmpty();
    }

    @Test
    @DisplayName("다른 사용자의 participation은 조회되지 않는다")
    void findByActivityIdInAndUserId_otherUser_notIncluded() {
        // given
        User otherUser = userRepository.save(User.builder()
                .name("다른사람")
                .studentNo("20250002")
                .password("password")
                .role(Role.MEMBER)
                .status(Status.ACTIVE)
                .build());

        participationRepository.save(Participation.builder()
                .activity(activity1).user(otherUser).type(ParticipationType.REGULAR).build());

        // when
        List<Long> activityIds = List.of(activity1.getId());
        List<Participation> result = participationRepository
                .findByActivityIdInAndUserId(activityIds, user.getId());

        // then
        assertThat(result).isEmpty();
    }
}