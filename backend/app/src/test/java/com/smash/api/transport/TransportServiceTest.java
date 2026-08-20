package com.smash.api.transport;

import com.smash.common.exception.BusinessException;
import com.smash.domain.activity.Activity;
import com.smash.domain.activity.ActivityRepository;
import com.smash.domain.transport.*;
import com.smash.domain.user.User;
import com.smash.domain.user.UserRepository;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

import java.util.List;
import java.util.Optional;

import static org.assertj.core.api.Assertions.*;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.BDDMockito.given;
import static org.mockito.Mockito.*;

@ExtendWith(MockitoExtension.class)
@org.mockito.junit.jupiter.MockitoSettings(
        strictness = org.mockito.quality.Strictness.LENIENT)
class TransportServiceTest {

    @Mock TransportGroupRepository transportGroupRepository;
    @Mock TransportMemberRepository transportMemberRepository;
    @Mock ActivityRepository activityRepository;
    @Mock UserRepository userRepository;

    @InjectMocks TransportService transportService;

    private Activity activity;
    private User user;

    @BeforeEach
    void setUp() {
        activity = mock(Activity.class);
        user = mock(User.class);
        given(user.getId()).willReturn(1L);
        given(user.getName()).willReturn("김동현");
    }

    @Test
    @DisplayName("택시 그룹 배정 성공")
    void assign_success() {
        // given
        TransportGroup savedGroup = mock(TransportGroup.class);
        given(savedGroup.getGroupNumber()).willReturn(1);

        given(activityRepository.findById(1L))
                .willReturn(Optional.of(activity));
        given(transportGroupRepository.findByActivityOrderByGroupNumber(activity))
                .willReturn(List.of());
        given(transportGroupRepository.save(any()))
                .willReturn(savedGroup);
        given(userRepository.findById(1L))
                .willReturn(Optional.of(user));

        TransportGroupRequest request = makeRequest(List.of(
                makeGroup(List.of(1L))
        ));

        // when & then
        assertThatNoException().isThrownBy(() ->
                transportService.assign(1L, request));

        verify(transportGroupRepository, times(1)).save(any());
        verify(transportMemberRepository, times(1)).save(any());
    }

    @Test
    @DisplayName("존재하지 않는 부원 배정 시 예외 발생")
    void assign_unknownUser_throwsException() {
        // given
        TransportGroup savedGroup = mock(TransportGroup.class);
        given(savedGroup.getGroupNumber()).willReturn(1);

        given(activityRepository.findById(1L))
                .willReturn(Optional.of(activity));
        given(transportGroupRepository.findByActivityOrderByGroupNumber(activity))
                .willReturn(List.of());
        given(transportGroupRepository.save(any()))
                .willReturn(savedGroup);
        given(userRepository.findById(999L))
                .willReturn(Optional.empty());

        TransportGroupRequest request = makeRequest(List.of(
                makeGroup(List.of(999L))
        ));

        // when & then
        assertThatThrownBy(() ->
                transportService.assign(1L, request))
                .isInstanceOf(BusinessException.class)
                .hasMessageContaining("존재하지 않는 부원입니다.");
    }

    @Test
    @DisplayName("택시 그룹 초기화 성공")
    void reset_success() {
        // given
        TransportGroup group = mock(TransportGroup.class);
        given(activityRepository.findById(1L))
                .willReturn(Optional.of(activity));
        given(transportGroupRepository.findByActivityOrderByGroupNumber(activity))
                .willReturn(List.of(group));

        // when
        transportService.reset(1L);

        // then
        verify(transportMemberRepository, times(1)).deleteByTransportGroup(group);
        verify(transportGroupRepository, times(1)).deleteByActivity(activity);
    }

    // 헬퍼 메서드
    private TransportGroupRequest makeRequest(
            List<TransportGroupRequest.Group> groups) {
        TransportGroupRequest request = new TransportGroupRequest();
        try {
            var field = request.getClass().getDeclaredField("groups");
            field.setAccessible(true);
            field.set(request, groups);
        } catch (Exception e) {
            throw new RuntimeException(e);
        }
        return request;
    }

    private TransportGroupRequest.Group makeGroup(List<Long> memberIds) {
        TransportGroupRequest.Group group =
                new TransportGroupRequest.Group();
        try {
            var field = group.getClass().getDeclaredField("memberIds");
            field.setAccessible(true);
            field.set(group, memberIds);
        } catch (Exception e) {
            throw new RuntimeException(e);
        }
        return group;
    }
}