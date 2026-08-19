package com.smash.api.admin;

import com.smash.domain.group.Group;
import com.smash.domain.user.MemberNote;
import com.smash.domain.user.User;
import lombok.Builder;
import lombok.Getter;

import java.util.List;

@Getter
@Builder
public class MemberDetailResponse {
    private Long id;
    private String name;
    private String studentNo;
    private String department;
    private String phone;
    private String role;
    private String status;
    private Long groupId;
    private String groupLabel;
    private List<NoteResponse> notes;

    @Getter
    @Builder
    public static class NoteResponse {
        private Long id;
        private String content;
        private String createdAt;

        public static NoteResponse of(MemberNote note) {
            return NoteResponse.builder()
                    .id(note.getId())
                    .content(note.getContent())
                    .createdAt(note.getCreatedAt().toString().substring(0, 16))
                    .build();
        }
    }

    public static MemberDetailResponse of(User user, Group group,
                                          List<MemberNote> notes) {
        return MemberDetailResponse.builder()
                .id(user.getId())
                .name(user.getName())
                .studentNo(user.getStudentNo())
                .department(user.getDepartment())
                .phone(user.getPhone())
                .role(user.getRole().name())
                .status(user.getStatus().name())
                .groupId(user.getGroupId())
                .groupLabel(group != null ? group.getLabel() : null)
                .notes(notes.stream()
                        .map(NoteResponse::of)
                        .toList())
                .build();
    }
}