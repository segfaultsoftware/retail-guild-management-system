RGMSRuntimeProbeExport = {
    complete = true,
    limits = {
        events = 128,
        membersPerObservation = 1000,
        observations = 20,
        sessions = 5,
    },
    schemaVersion = 1,
    sessions = {
        {
            boundary = "initial",
            events = {
                {
                    availability = {
                        canRequestRosterUpdate = false,
                        clubId = false,
                        memberId = false,
                    },
                    name = "PROBE_START",
                    sequence = 1,
                },
                {
                    availability = {
                        canRequestRosterUpdate = true,
                        clubId = false,
                        memberId = false,
                    },
                    canRequestRosterUpdate = false,
                    name = "GUILD_ROSTER_UPDATE",
                    sequence = 2,
                },
                {
                    availability = {
                        canRequestRosterUpdate = false,
                        clubId = false,
                        memberId = false,
                    },
                    name = "MANUAL_SNAPSHOT",
                    sequence = 3,
                },
                {
                    availability = {
                        canRequestRosterUpdate = false,
                        clubId = false,
                        memberId = false,
                    },
                    name = "MANUAL_SNAPSHOT",
                    sequence = 4,
                },
                {
                    availability = {
                        canRequestRosterUpdate = true,
                        clubId = false,
                        memberId = false,
                    },
                    canRequestRosterUpdate = false,
                    name = "GUILD_ROSTER_UPDATE",
                    sequence = 5,
                },
                {
                    availability = {
                        canRequestRosterUpdate = false,
                        clubId = false,
                        memberId = false,
                    },
                    name = "MANUAL_SNAPSHOT",
                    sequence = 6,
                },
                {
                    availability = {
                        canRequestRosterUpdate = false,
                        clubId = false,
                        memberId = false,
                    },
                    name = "MANUAL_SNAPSHOT",
                    sequence = 7,
                },
                {
                    availability = {
                        canRequestRosterUpdate = true,
                        clubId = false,
                        memberId = false,
                    },
                    canRequestRosterUpdate = false,
                    name = "GUILD_ROSTER_UPDATE",
                    sequence = 8,
                },
                {
                    availability = {
                        canRequestRosterUpdate = false,
                        clubId = false,
                        memberId = false,
                    },
                    name = "MARK_RELOAD",
                    sequence = 9,
                },
                {
                    availability = {
                        canRequestRosterUpdate = false,
                        clubId = false,
                        memberId = false,
                    },
                    name = "PLAYER_LEAVING_WORLD",
                    sequence = 10,
                },
                {
                    availability = {
                        canRequestRosterUpdate = false,
                        clubId = false,
                        memberId = false,
                    },
                    name = "PLAYER_LOGOUT",
                    sequence = 11,
                },
            },
            index = 1,
            observations = {
                {
                    availability = {
                        guildRosterMemberCount = true,
                        guildRosterOnlineCount = true,
                        memberListCount = true,
                    },
                    errors = {
                    },
                    guild = {
                        availability = {
                            clubId = true,
                            memberCount = true,
                            name = true,
                            realm = false,
                        },
                        clubId = "Club-001",
                        memberCount = 56,
                        name = "Guild-001",
                    },
                    guildRosterMemberCount = 56,
                    guildRosterOnlineCount = 3,
                    memberListCount = 56,
                    memberSource = "club",
                    members = {
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-001",
                            name = "First-002 Surname-002",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-002",
                            name = "First-003 Surname-003",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-003",
                            name = "First-004 Surname-004",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-004",
                            name = "First-005 Surname-005",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-005",
                            name = "First-006 Surname-006",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-006",
                            name = "First-007 Surname-007",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-007",
                            name = "First-008 Surname-008",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-008",
                            name = "First-009 Surname-009",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-009",
                            name = "First-010 Surname-010",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-010",
                            name = "First-011 Surname-011",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-011",
                            name = "First-012 Surname-012",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-012",
                            name = "First-013 Surname-013",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-013",
                            name = "First-014 Surname-014",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-014",
                            name = "First-015 Surname-015",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-015",
                            name = "First-016 Surname-016",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-016",
                            name = "First-017 Surname-017",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-017",
                            name = "First-018 Surname-018",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-018",
                            name = "First-019 Surname-013",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-019",
                            name = "First-020 Surname-019",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-020",
                            name = "First-021 Surname-020",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-021",
                            name = "First-022 Surname-021",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-022",
                            name = "First-023 Surname-022",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-023",
                            name = "First-024 Surname-023",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-024",
                            name = "First-025 Surname-024",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-025",
                            name = "First-026 Surname-025",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-026",
                            name = "First-027 Surname-026",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-027",
                            name = "First-028 Surname-010",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-028",
                            name = "First-029 Surname-027",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-029",
                            name = "First-030 Surname-028",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-030",
                            name = "First-031 Surname-011",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-031",
                            name = "First-032 Surname-029",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-032",
                            name = "First-033 Surname-030",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-033",
                            name = "First-034 Surname-014",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-034",
                            name = "First-035 Surname-031",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-035",
                            name = "First-036 Surname-032",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-036",
                            name = "First-037 Surname-033",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-037",
                            name = "First-038 Surname-014",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-038",
                            name = "First-039 Surname-034",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-039",
                            name = "First-040 Surname-035",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-040",
                            name = "First-041 Surname-036",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-041",
                            name = "First-042 Surname-037",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-042",
                            name = "First-043 Surname-038",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-043",
                            name = "First-044 Surname-039",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-044",
                            name = "First-045 Surname-040",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-045",
                            name = "First-046 Surname-021",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-046",
                            name = "First-047 Surname-041",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-047",
                            name = "First-001 Surname-001",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-048",
                            name = "First-048 Surname-042",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-049",
                            name = "First-049 Surname-043",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-050",
                            name = "First-050 Surname-044",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-051",
                            name = "First-051 Surname-045",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-052",
                            name = "First-052 Surname-046",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-053",
                            name = "First-053 Surname-047",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-054",
                            name = "First-054 Surname-048",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-055",
                            name = "First-055 Surname-049",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-056",
                            name = "First-056 Surname-050",
                        },
                    },
                    sequence = 1,
                    trigger = "PROBE_START",
                },
                {
                    availability = {
                        guildRosterMemberCount = true,
                        guildRosterOnlineCount = true,
                        memberListCount = true,
                    },
                    errors = {
                    },
                    guild = {
                        availability = {
                            clubId = true,
                            memberCount = true,
                            name = true,
                            realm = false,
                        },
                        clubId = "Club-001",
                        memberCount = 56,
                        name = "Guild-001",
                    },
                    guildRosterMemberCount = 56,
                    guildRosterOnlineCount = 3,
                    memberListCount = 56,
                    memberSource = "club",
                    members = {
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-001",
                            name = "First-002 Surname-002",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-002",
                            name = "First-003 Surname-003",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-003",
                            name = "First-004 Surname-004",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-004",
                            name = "First-005 Surname-005",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-005",
                            name = "First-006 Surname-006",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-006",
                            name = "First-007 Surname-007",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-007",
                            name = "First-008 Surname-008",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-008",
                            name = "First-009 Surname-009",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-009",
                            name = "First-010 Surname-010",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-010",
                            name = "First-011 Surname-011",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-011",
                            name = "First-012 Surname-012",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-012",
                            name = "First-013 Surname-013",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-013",
                            name = "First-014 Surname-014",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-014",
                            name = "First-015 Surname-015",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-015",
                            name = "First-016 Surname-016",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-016",
                            name = "First-017 Surname-017",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-017",
                            name = "First-018 Surname-018",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-018",
                            name = "First-019 Surname-013",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-019",
                            name = "First-020 Surname-019",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-020",
                            name = "First-021 Surname-020",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-021",
                            name = "First-022 Surname-021",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-022",
                            name = "First-023 Surname-022",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-023",
                            name = "First-024 Surname-023",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-024",
                            name = "First-025 Surname-024",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-025",
                            name = "First-026 Surname-025",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-026",
                            name = "First-027 Surname-026",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-027",
                            name = "First-028 Surname-010",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-028",
                            name = "First-029 Surname-027",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-029",
                            name = "First-030 Surname-028",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-030",
                            name = "First-031 Surname-011",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-031",
                            name = "First-032 Surname-029",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-032",
                            name = "First-033 Surname-030",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-033",
                            name = "First-034 Surname-014",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-034",
                            name = "First-035 Surname-031",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-035",
                            name = "First-036 Surname-032",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-036",
                            name = "First-037 Surname-033",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-037",
                            name = "First-038 Surname-014",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-038",
                            name = "First-039 Surname-034",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-039",
                            name = "First-040 Surname-035",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-040",
                            name = "First-041 Surname-036",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-041",
                            name = "First-042 Surname-037",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-042",
                            name = "First-043 Surname-038",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-043",
                            name = "First-044 Surname-039",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-044",
                            name = "First-045 Surname-040",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-045",
                            name = "First-046 Surname-021",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-046",
                            name = "First-047 Surname-041",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-047",
                            name = "First-001 Surname-001",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-048",
                            name = "First-048 Surname-042",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-049",
                            name = "First-049 Surname-043",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-050",
                            name = "First-050 Surname-044",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-051",
                            name = "First-051 Surname-045",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-052",
                            name = "First-052 Surname-046",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-053",
                            name = "First-053 Surname-047",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-054",
                            name = "First-054 Surname-048",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-055",
                            name = "First-055 Surname-049",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-056",
                            name = "First-056 Surname-050",
                        },
                    },
                    sequence = 2,
                    trigger = "GUILD_ROSTER_UPDATE",
                },
                {
                    availability = {
                        guildRosterMemberCount = true,
                        guildRosterOnlineCount = true,
                        memberListCount = true,
                    },
                    errors = {
                    },
                    guild = {
                        availability = {
                            clubId = true,
                            memberCount = true,
                            name = true,
                            realm = false,
                        },
                        clubId = "Club-001",
                        memberCount = 56,
                        name = "Guild-001",
                    },
                    guildRosterMemberCount = 56,
                    guildRosterOnlineCount = 3,
                    memberListCount = 56,
                    memberSource = "club",
                    members = {
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-001",
                            name = "First-002 Surname-002",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-002",
                            name = "First-003 Surname-003",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-003",
                            name = "First-004 Surname-004",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-004",
                            name = "First-005 Surname-005",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-005",
                            name = "First-006 Surname-006",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-006",
                            name = "First-007 Surname-007",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-007",
                            name = "First-008 Surname-008",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-008",
                            name = "First-009 Surname-009",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-009",
                            name = "First-010 Surname-010",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-010",
                            name = "First-011 Surname-011",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-011",
                            name = "First-012 Surname-012",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-012",
                            name = "First-013 Surname-013",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-013",
                            name = "First-014 Surname-014",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-014",
                            name = "First-015 Surname-015",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-015",
                            name = "First-016 Surname-016",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-016",
                            name = "First-017 Surname-017",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-017",
                            name = "First-018 Surname-018",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-018",
                            name = "First-019 Surname-013",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-019",
                            name = "First-020 Surname-019",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-020",
                            name = "First-021 Surname-020",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-021",
                            name = "First-022 Surname-021",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-022",
                            name = "First-023 Surname-022",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-023",
                            name = "First-024 Surname-023",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-024",
                            name = "First-025 Surname-024",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-025",
                            name = "First-026 Surname-025",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-026",
                            name = "First-027 Surname-026",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-027",
                            name = "First-028 Surname-010",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-028",
                            name = "First-029 Surname-027",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-029",
                            name = "First-030 Surname-028",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-030",
                            name = "First-031 Surname-011",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-031",
                            name = "First-032 Surname-029",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-032",
                            name = "First-033 Surname-030",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-033",
                            name = "First-034 Surname-014",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-034",
                            name = "First-035 Surname-031",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-035",
                            name = "First-036 Surname-032",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-036",
                            name = "First-037 Surname-033",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-037",
                            name = "First-038 Surname-014",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-038",
                            name = "First-039 Surname-034",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-039",
                            name = "First-040 Surname-035",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-040",
                            name = "First-041 Surname-036",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-041",
                            name = "First-042 Surname-037",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-042",
                            name = "First-043 Surname-038",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-043",
                            name = "First-044 Surname-039",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-044",
                            name = "First-045 Surname-040",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-045",
                            name = "First-046 Surname-021",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-046",
                            name = "First-047 Surname-041",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-047",
                            name = "First-001 Surname-001",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-048",
                            name = "First-048 Surname-042",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-049",
                            name = "First-049 Surname-043",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-050",
                            name = "First-050 Surname-044",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-051",
                            name = "First-051 Surname-045",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-052",
                            name = "First-052 Surname-046",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-053",
                            name = "First-053 Surname-047",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-054",
                            name = "First-054 Surname-048",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-055",
                            name = "First-055 Surname-049",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-056",
                            name = "First-056 Surname-050",
                        },
                    },
                    sequence = 3,
                    trigger = "MANUAL_SNAPSHOT",
                },
                {
                    availability = {
                        guildRosterMemberCount = true,
                        guildRosterOnlineCount = true,
                        memberListCount = true,
                    },
                    errors = {
                    },
                    guild = {
                        availability = {
                            clubId = true,
                            memberCount = true,
                            name = true,
                            realm = false,
                        },
                        clubId = "Club-001",
                        memberCount = 56,
                        name = "Guild-001",
                    },
                    guildRosterMemberCount = 56,
                    guildRosterOnlineCount = 3,
                    memberListCount = 56,
                    memberSource = "club",
                    members = {
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-001",
                            name = "First-002 Surname-002",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-002",
                            name = "First-003 Surname-003",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-003",
                            name = "First-004 Surname-004",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-004",
                            name = "First-005 Surname-005",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-005",
                            name = "First-006 Surname-006",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-006",
                            name = "First-007 Surname-007",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-007",
                            name = "First-008 Surname-008",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-008",
                            name = "First-009 Surname-009",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-009",
                            name = "First-010 Surname-010",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-010",
                            name = "First-011 Surname-011",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-011",
                            name = "First-012 Surname-012",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-012",
                            name = "First-013 Surname-013",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-013",
                            name = "First-014 Surname-014",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-014",
                            name = "First-015 Surname-015",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-015",
                            name = "First-016 Surname-016",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-016",
                            name = "First-017 Surname-017",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-017",
                            name = "First-018 Surname-018",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-018",
                            name = "First-019 Surname-013",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-019",
                            name = "First-020 Surname-019",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-020",
                            name = "First-021 Surname-020",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-021",
                            name = "First-022 Surname-021",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-022",
                            name = "First-023 Surname-022",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-023",
                            name = "First-024 Surname-023",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-024",
                            name = "First-025 Surname-024",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-025",
                            name = "First-026 Surname-025",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-026",
                            name = "First-027 Surname-026",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-027",
                            name = "First-028 Surname-010",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-028",
                            name = "First-029 Surname-027",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-029",
                            name = "First-030 Surname-028",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-030",
                            name = "First-031 Surname-011",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-031",
                            name = "First-032 Surname-029",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-032",
                            name = "First-033 Surname-030",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-033",
                            name = "First-034 Surname-014",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-034",
                            name = "First-035 Surname-031",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-035",
                            name = "First-036 Surname-032",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-036",
                            name = "First-037 Surname-033",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-037",
                            name = "First-038 Surname-014",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-038",
                            name = "First-039 Surname-034",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-039",
                            name = "First-040 Surname-035",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-040",
                            name = "First-041 Surname-036",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-041",
                            name = "First-042 Surname-037",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-042",
                            name = "First-043 Surname-038",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-043",
                            name = "First-044 Surname-039",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-044",
                            name = "First-045 Surname-040",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-045",
                            name = "First-046 Surname-021",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-046",
                            name = "First-047 Surname-041",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-047",
                            name = "First-001 Surname-001",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-048",
                            name = "First-048 Surname-042",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-049",
                            name = "First-049 Surname-043",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-050",
                            name = "First-050 Surname-044",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-051",
                            name = "First-051 Surname-045",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-052",
                            name = "First-052 Surname-046",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-053",
                            name = "First-053 Surname-047",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-054",
                            name = "First-054 Surname-048",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-055",
                            name = "First-055 Surname-049",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-056",
                            name = "First-056 Surname-050",
                        },
                    },
                    sequence = 4,
                    trigger = "MANUAL_SNAPSHOT",
                },
                {
                    availability = {
                        guildRosterMemberCount = true,
                        guildRosterOnlineCount = true,
                        memberListCount = true,
                    },
                    errors = {
                    },
                    guild = {
                        availability = {
                            clubId = true,
                            memberCount = true,
                            name = true,
                            realm = false,
                        },
                        clubId = "Club-001",
                        memberCount = 56,
                        name = "Guild-001",
                    },
                    guildRosterMemberCount = 56,
                    guildRosterOnlineCount = 3,
                    memberListCount = 56,
                    memberSource = "club",
                    members = {
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-001",
                            name = "First-002 Surname-002",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-002",
                            name = "First-003 Surname-003",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-003",
                            name = "First-004 Surname-004",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-004",
                            name = "First-005 Surname-005",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-005",
                            name = "First-006 Surname-006",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-006",
                            name = "First-007 Surname-007",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-007",
                            name = "First-008 Surname-008",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-008",
                            name = "First-009 Surname-009",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-009",
                            name = "First-010 Surname-010",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-010",
                            name = "First-011 Surname-011",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-011",
                            name = "First-012 Surname-012",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-012",
                            name = "First-013 Surname-013",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-013",
                            name = "First-014 Surname-014",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-014",
                            name = "First-015 Surname-015",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-015",
                            name = "First-016 Surname-016",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-016",
                            name = "First-017 Surname-017",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-017",
                            name = "First-018 Surname-018",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-018",
                            name = "First-019 Surname-013",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-019",
                            name = "First-020 Surname-019",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-020",
                            name = "First-021 Surname-020",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-021",
                            name = "First-022 Surname-021",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-022",
                            name = "First-023 Surname-022",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-023",
                            name = "First-024 Surname-023",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-024",
                            name = "First-025 Surname-024",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-025",
                            name = "First-026 Surname-025",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-026",
                            name = "First-027 Surname-026",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-027",
                            name = "First-028 Surname-010",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-028",
                            name = "First-029 Surname-027",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-029",
                            name = "First-030 Surname-028",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-030",
                            name = "First-031 Surname-011",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-031",
                            name = "First-032 Surname-029",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-032",
                            name = "First-033 Surname-030",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-033",
                            name = "First-034 Surname-014",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-034",
                            name = "First-035 Surname-031",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-035",
                            name = "First-036 Surname-032",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-036",
                            name = "First-037 Surname-033",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-037",
                            name = "First-038 Surname-014",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-038",
                            name = "First-039 Surname-034",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-039",
                            name = "First-040 Surname-035",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-040",
                            name = "First-041 Surname-036",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-041",
                            name = "First-042 Surname-037",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-042",
                            name = "First-043 Surname-038",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-043",
                            name = "First-044 Surname-039",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-044",
                            name = "First-045 Surname-040",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-045",
                            name = "First-046 Surname-021",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-046",
                            name = "First-047 Surname-041",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-047",
                            name = "First-001 Surname-001",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-048",
                            name = "First-048 Surname-042",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-049",
                            name = "First-049 Surname-043",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-050",
                            name = "First-050 Surname-044",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-051",
                            name = "First-051 Surname-045",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-052",
                            name = "First-052 Surname-046",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-053",
                            name = "First-053 Surname-047",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-054",
                            name = "First-054 Surname-048",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-055",
                            name = "First-055 Surname-049",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-056",
                            name = "First-056 Surname-050",
                        },
                    },
                    sequence = 5,
                    trigger = "GUILD_ROSTER_UPDATE",
                },
                {
                    availability = {
                        guildRosterMemberCount = true,
                        guildRosterOnlineCount = true,
                        memberListCount = true,
                    },
                    errors = {
                    },
                    guild = {
                        availability = {
                            clubId = true,
                            memberCount = true,
                            name = true,
                            realm = false,
                        },
                        clubId = "Club-001",
                        memberCount = 56,
                        name = "Guild-001",
                    },
                    guildRosterMemberCount = 56,
                    guildRosterOnlineCount = 3,
                    memberListCount = 56,
                    memberSource = "club",
                    members = {
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-001",
                            name = "First-002 Surname-002",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-002",
                            name = "First-003 Surname-003",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-003",
                            name = "First-004 Surname-004",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-004",
                            name = "First-005 Surname-005",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-005",
                            name = "First-006 Surname-006",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-006",
                            name = "First-007 Surname-007",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-007",
                            name = "First-008 Surname-008",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-008",
                            name = "First-009 Surname-009",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-009",
                            name = "First-010 Surname-010",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-010",
                            name = "First-011 Surname-011",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-011",
                            name = "First-012 Surname-012",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-012",
                            name = "First-013 Surname-013",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-013",
                            name = "First-014 Surname-014",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-014",
                            name = "First-015 Surname-015",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-015",
                            name = "First-016 Surname-016",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-016",
                            name = "First-017 Surname-017",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-017",
                            name = "First-018 Surname-018",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-018",
                            name = "First-019 Surname-013",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-019",
                            name = "First-020 Surname-019",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-020",
                            name = "First-021 Surname-020",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-021",
                            name = "First-022 Surname-021",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-022",
                            name = "First-023 Surname-022",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-023",
                            name = "First-024 Surname-023",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-024",
                            name = "First-025 Surname-024",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-025",
                            name = "First-026 Surname-025",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-026",
                            name = "First-027 Surname-026",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-027",
                            name = "First-028 Surname-010",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-028",
                            name = "First-029 Surname-027",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-029",
                            name = "First-030 Surname-028",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-030",
                            name = "First-031 Surname-011",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-031",
                            name = "First-032 Surname-029",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-032",
                            name = "First-033 Surname-030",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-033",
                            name = "First-034 Surname-014",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-034",
                            name = "First-035 Surname-031",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-035",
                            name = "First-036 Surname-032",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-036",
                            name = "First-037 Surname-033",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-037",
                            name = "First-038 Surname-014",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-038",
                            name = "First-039 Surname-034",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-039",
                            name = "First-040 Surname-035",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-040",
                            name = "First-041 Surname-036",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-041",
                            name = "First-042 Surname-037",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-042",
                            name = "First-043 Surname-038",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-043",
                            name = "First-044 Surname-039",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-044",
                            name = "First-045 Surname-040",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-045",
                            name = "First-046 Surname-021",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-046",
                            name = "First-047 Surname-041",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-047",
                            name = "First-001 Surname-001",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-048",
                            name = "First-048 Surname-042",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-049",
                            name = "First-049 Surname-043",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-050",
                            name = "First-050 Surname-044",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-051",
                            name = "First-051 Surname-045",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-052",
                            name = "First-052 Surname-046",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-053",
                            name = "First-053 Surname-047",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-054",
                            name = "First-054 Surname-048",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-055",
                            name = "First-055 Surname-049",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-056",
                            name = "First-056 Surname-050",
                        },
                    },
                    sequence = 6,
                    trigger = "MANUAL_SNAPSHOT",
                },
                {
                    availability = {
                        guildRosterMemberCount = true,
                        guildRosterOnlineCount = true,
                        memberListCount = true,
                    },
                    errors = {
                    },
                    guild = {
                        availability = {
                            clubId = true,
                            memberCount = true,
                            name = true,
                            realm = false,
                        },
                        clubId = "Club-001",
                        memberCount = 56,
                        name = "Guild-001",
                    },
                    guildRosterMemberCount = 56,
                    guildRosterOnlineCount = 3,
                    memberListCount = 56,
                    memberSource = "club",
                    members = {
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-001",
                            name = "First-002 Surname-002",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-002",
                            name = "First-003 Surname-003",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-003",
                            name = "First-004 Surname-004",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-004",
                            name = "First-005 Surname-005",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-005",
                            name = "First-006 Surname-006",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-006",
                            name = "First-007 Surname-007",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-007",
                            name = "First-008 Surname-008",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-008",
                            name = "First-009 Surname-009",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-009",
                            name = "First-010 Surname-010",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-010",
                            name = "First-011 Surname-011",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-011",
                            name = "First-012 Surname-012",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-012",
                            name = "First-013 Surname-013",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-013",
                            name = "First-014 Surname-014",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-014",
                            name = "First-015 Surname-015",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-015",
                            name = "First-016 Surname-016",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-016",
                            name = "First-017 Surname-017",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-017",
                            name = "First-018 Surname-018",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-018",
                            name = "First-019 Surname-013",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-019",
                            name = "First-020 Surname-019",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-020",
                            name = "First-021 Surname-020",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-021",
                            name = "First-022 Surname-021",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-022",
                            name = "First-023 Surname-022",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-023",
                            name = "First-024 Surname-023",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-024",
                            name = "First-025 Surname-024",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-025",
                            name = "First-026 Surname-025",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-026",
                            name = "First-027 Surname-026",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-027",
                            name = "First-028 Surname-010",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-028",
                            name = "First-029 Surname-027",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-029",
                            name = "First-030 Surname-028",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-030",
                            name = "First-031 Surname-011",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-031",
                            name = "First-032 Surname-029",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-032",
                            name = "First-033 Surname-030",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-033",
                            name = "First-034 Surname-014",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-034",
                            name = "First-035 Surname-031",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-035",
                            name = "First-036 Surname-032",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-036",
                            name = "First-037 Surname-033",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-037",
                            name = "First-038 Surname-014",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-038",
                            name = "First-039 Surname-034",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-039",
                            name = "First-040 Surname-035",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-040",
                            name = "First-041 Surname-036",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-041",
                            name = "First-042 Surname-037",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-042",
                            name = "First-043 Surname-038",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-043",
                            name = "First-044 Surname-039",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-044",
                            name = "First-045 Surname-040",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-045",
                            name = "First-046 Surname-021",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-046",
                            name = "First-047 Surname-041",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-047",
                            name = "First-001 Surname-001",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-048",
                            name = "First-048 Surname-042",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-049",
                            name = "First-049 Surname-043",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-050",
                            name = "First-050 Surname-044",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-051",
                            name = "First-051 Surname-045",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-052",
                            name = "First-052 Surname-046",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-053",
                            name = "First-053 Surname-047",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-054",
                            name = "First-054 Surname-048",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-055",
                            name = "First-055 Surname-049",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-056",
                            name = "First-056 Surname-050",
                        },
                    },
                    sequence = 7,
                    trigger = "MANUAL_SNAPSHOT",
                },
                {
                    availability = {
                        guildRosterMemberCount = true,
                        guildRosterOnlineCount = true,
                        memberListCount = true,
                    },
                    errors = {
                    },
                    guild = {
                        availability = {
                            clubId = true,
                            memberCount = true,
                            name = true,
                            realm = false,
                        },
                        clubId = "Club-001",
                        memberCount = 56,
                        name = "Guild-001",
                    },
                    guildRosterMemberCount = 56,
                    guildRosterOnlineCount = 3,
                    memberListCount = 56,
                    memberSource = "club",
                    members = {
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-001",
                            name = "First-002 Surname-002",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-002",
                            name = "First-003 Surname-003",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-003",
                            name = "First-004 Surname-004",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-004",
                            name = "First-005 Surname-005",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-005",
                            name = "First-006 Surname-006",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-006",
                            name = "First-007 Surname-007",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-007",
                            name = "First-008 Surname-008",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-008",
                            name = "First-009 Surname-009",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-009",
                            name = "First-010 Surname-010",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-010",
                            name = "First-011 Surname-011",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-011",
                            name = "First-012 Surname-012",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-012",
                            name = "First-013 Surname-013",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-013",
                            name = "First-014 Surname-014",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-014",
                            name = "First-015 Surname-015",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-015",
                            name = "First-016 Surname-016",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-016",
                            name = "First-017 Surname-017",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-017",
                            name = "First-018 Surname-018",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-018",
                            name = "First-019 Surname-013",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-019",
                            name = "First-020 Surname-019",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-020",
                            name = "First-021 Surname-020",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-021",
                            name = "First-022 Surname-021",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-022",
                            name = "First-023 Surname-022",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-023",
                            name = "First-024 Surname-023",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-024",
                            name = "First-025 Surname-024",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-025",
                            name = "First-026 Surname-025",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-026",
                            name = "First-027 Surname-026",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-027",
                            name = "First-028 Surname-010",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-028",
                            name = "First-029 Surname-027",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-029",
                            name = "First-030 Surname-028",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-030",
                            name = "First-031 Surname-011",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-031",
                            name = "First-032 Surname-029",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-032",
                            name = "First-033 Surname-030",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-033",
                            name = "First-034 Surname-014",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-034",
                            name = "First-035 Surname-031",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-035",
                            name = "First-036 Surname-032",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-036",
                            name = "First-037 Surname-033",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-037",
                            name = "First-038 Surname-014",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-038",
                            name = "First-039 Surname-034",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-039",
                            name = "First-040 Surname-035",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-040",
                            name = "First-041 Surname-036",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-041",
                            name = "First-042 Surname-037",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-042",
                            name = "First-043 Surname-038",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-043",
                            name = "First-044 Surname-039",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-044",
                            name = "First-045 Surname-040",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-045",
                            name = "First-046 Surname-021",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-046",
                            name = "First-047 Surname-041",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-047",
                            name = "First-001 Surname-001",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-048",
                            name = "First-048 Surname-042",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-049",
                            name = "First-049 Surname-043",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-050",
                            name = "First-050 Surname-044",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-051",
                            name = "First-051 Surname-045",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-052",
                            name = "First-052 Surname-046",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-053",
                            name = "First-053 Surname-047",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-054",
                            name = "First-054 Surname-048",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-055",
                            name = "First-055 Surname-049",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-056",
                            name = "First-056 Surname-050",
                        },
                    },
                    sequence = 8,
                    trigger = "GUILD_ROSTER_UPDATE",
                },
                {
                    availability = {
                        guildRosterMemberCount = true,
                        guildRosterOnlineCount = true,
                        memberListCount = true,
                    },
                    errors = {
                    },
                    guild = {
                        availability = {
                            clubId = true,
                            memberCount = true,
                            name = true,
                            realm = false,
                        },
                        clubId = "Club-001",
                        memberCount = 56,
                        name = "Guild-001",
                    },
                    guildRosterMemberCount = 56,
                    guildRosterOnlineCount = 3,
                    memberListCount = 56,
                    memberSource = "club",
                    members = {
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-001",
                            name = "First-002 Surname-002",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-002",
                            name = "First-003 Surname-003",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-003",
                            name = "First-004 Surname-004",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-004",
                            name = "First-005 Surname-005",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-005",
                            name = "First-006 Surname-006",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-006",
                            name = "First-007 Surname-007",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-007",
                            name = "First-008 Surname-008",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-008",
                            name = "First-009 Surname-009",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-009",
                            name = "First-010 Surname-010",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-010",
                            name = "First-011 Surname-011",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-011",
                            name = "First-012 Surname-012",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-012",
                            name = "First-013 Surname-013",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-013",
                            name = "First-014 Surname-014",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-014",
                            name = "First-015 Surname-015",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-015",
                            name = "First-016 Surname-016",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-016",
                            name = "First-017 Surname-017",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-017",
                            name = "First-018 Surname-018",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-018",
                            name = "First-019 Surname-013",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-019",
                            name = "First-020 Surname-019",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-020",
                            name = "First-021 Surname-020",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-021",
                            name = "First-022 Surname-021",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-022",
                            name = "First-023 Surname-022",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-023",
                            name = "First-024 Surname-023",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-024",
                            name = "First-025 Surname-024",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-025",
                            name = "First-026 Surname-025",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-026",
                            name = "First-027 Surname-026",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-027",
                            name = "First-028 Surname-010",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-028",
                            name = "First-029 Surname-027",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-029",
                            name = "First-030 Surname-028",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-030",
                            name = "First-031 Surname-011",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-031",
                            name = "First-032 Surname-029",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-032",
                            name = "First-033 Surname-030",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-033",
                            name = "First-034 Surname-014",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-034",
                            name = "First-035 Surname-031",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-035",
                            name = "First-036 Surname-032",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-036",
                            name = "First-037 Surname-033",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-037",
                            name = "First-038 Surname-014",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-038",
                            name = "First-039 Surname-034",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-039",
                            name = "First-040 Surname-035",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-040",
                            name = "First-041 Surname-036",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-041",
                            name = "First-042 Surname-037",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-042",
                            name = "First-043 Surname-038",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-043",
                            name = "First-044 Surname-039",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-044",
                            name = "First-045 Surname-040",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-045",
                            name = "First-046 Surname-021",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-046",
                            name = "First-047 Surname-041",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-047",
                            name = "First-001 Surname-001",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-048",
                            name = "First-048 Surname-042",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-049",
                            name = "First-049 Surname-043",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-050",
                            name = "First-050 Surname-044",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-051",
                            name = "First-051 Surname-045",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-052",
                            name = "First-052 Surname-046",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-053",
                            name = "First-053 Surname-047",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-054",
                            name = "First-054 Surname-048",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-055",
                            name = "First-055 Surname-049",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-056",
                            name = "First-056 Surname-050",
                        },
                    },
                    sequence = 9,
                    trigger = "PLAYER_LEAVING_WORLD",
                },
                {
                    availability = {
                        guildRosterMemberCount = true,
                        guildRosterOnlineCount = true,
                        memberListCount = true,
                    },
                    errors = {
                    },
                    guild = {
                        availability = {
                            clubId = true,
                            memberCount = true,
                            name = true,
                            realm = false,
                        },
                        clubId = "Club-001",
                        memberCount = 56,
                        name = "Guild-001",
                    },
                    guildRosterMemberCount = 56,
                    guildRosterOnlineCount = 3,
                    memberListCount = 56,
                    memberSource = "club",
                    members = {
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-001",
                            name = "First-002 Surname-002",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-002",
                            name = "First-003 Surname-003",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-003",
                            name = "First-004 Surname-004",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-004",
                            name = "First-005 Surname-005",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-005",
                            name = "First-006 Surname-006",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-006",
                            name = "First-007 Surname-007",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-007",
                            name = "First-008 Surname-008",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-008",
                            name = "First-009 Surname-009",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-009",
                            name = "First-010 Surname-010",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-010",
                            name = "First-011 Surname-011",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-011",
                            name = "First-012 Surname-012",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-012",
                            name = "First-013 Surname-013",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-013",
                            name = "First-014 Surname-014",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-014",
                            name = "First-015 Surname-015",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-015",
                            name = "First-016 Surname-016",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-016",
                            name = "First-017 Surname-017",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-017",
                            name = "First-018 Surname-018",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-018",
                            name = "First-019 Surname-013",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-019",
                            name = "First-020 Surname-019",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-020",
                            name = "First-021 Surname-020",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-021",
                            name = "First-022 Surname-021",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-022",
                            name = "First-023 Surname-022",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-023",
                            name = "First-024 Surname-023",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-024",
                            name = "First-025 Surname-024",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-025",
                            name = "First-026 Surname-025",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-026",
                            name = "First-027 Surname-026",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-027",
                            name = "First-028 Surname-010",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-028",
                            name = "First-029 Surname-027",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-029",
                            name = "First-030 Surname-028",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-030",
                            name = "First-031 Surname-011",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-031",
                            name = "First-032 Surname-029",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-032",
                            name = "First-033 Surname-030",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-033",
                            name = "First-034 Surname-014",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-034",
                            name = "First-035 Surname-031",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-035",
                            name = "First-036 Surname-032",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-036",
                            name = "First-037 Surname-033",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-037",
                            name = "First-038 Surname-014",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-038",
                            name = "First-039 Surname-034",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-039",
                            name = "First-040 Surname-035",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-040",
                            name = "First-041 Surname-036",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-041",
                            name = "First-042 Surname-037",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-042",
                            name = "First-043 Surname-038",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-043",
                            name = "First-044 Surname-039",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-044",
                            name = "First-045 Surname-040",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-045",
                            name = "First-046 Surname-021",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-046",
                            name = "First-047 Surname-041",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-047",
                            name = "First-001 Surname-001",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-048",
                            name = "First-048 Surname-042",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-049",
                            name = "First-049 Surname-043",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-050",
                            name = "First-050 Surname-044",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-051",
                            name = "First-051 Surname-045",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-052",
                            name = "First-052 Surname-046",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-053",
                            name = "First-053 Surname-047",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-054",
                            name = "First-054 Surname-048",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-055",
                            name = "First-055 Surname-049",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-056",
                            name = "First-056 Surname-050",
                        },
                    },
                    sequence = 10,
                    trigger = "PLAYER_LOGOUT",
                },
            },
            runtime = {
                availability = {
                    build = true,
                    interface = true,
                    normalizedRealmName = true,
                    playerName = true,
                    playerRealm = true,
                    productId = true,
                    realmName = true,
                    region = true,
                    version = true,
                },
                build = "70888",
                errors = {
                },
                interface = 16001,
                normalizedRealmName = "Realm-002",
                playerName = "First-001 Surname-001",
                playerRealm = "Realm-003",
                productId = 18,
                realmName = "Realm-001",
                region = "US",
                version = "1.60.1",
            },
        },
        {
            boundary = "reload",
            events = {
                {
                    availability = {
                        canRequestRosterUpdate = false,
                        clubId = false,
                        memberId = false,
                    },
                    name = "ADDON_LOADED",
                    sequence = 1,
                },
                {
                    availability = {
                        canRequestRosterUpdate = false,
                        clubId = false,
                        memberId = false,
                    },
                    name = "INITIAL_CLUBS_LOADED",
                    sequence = 2,
                },
                {
                    availability = {
                        canRequestRosterUpdate = false,
                        clubId = false,
                        memberId = false,
                    },
                    name = "PLAYER_LOGIN",
                    sequence = 3,
                },
                {
                    availability = {
                        canRequestRosterUpdate = false,
                        clubId = false,
                        memberId = false,
                    },
                    name = "PLAYER_ENTERING_WORLD",
                    sequence = 4,
                },
                {
                    availability = {
                        canRequestRosterUpdate = true,
                        clubId = false,
                        memberId = false,
                    },
                    canRequestRosterUpdate = false,
                    name = "GUILD_ROSTER_UPDATE",
                    sequence = 5,
                },
                {
                    availability = {
                        canRequestRosterUpdate = true,
                        clubId = false,
                        memberId = false,
                    },
                    canRequestRosterUpdate = false,
                    name = "GUILD_ROSTER_UPDATE",
                    sequence = 6,
                },
                {
                    availability = {
                        canRequestRosterUpdate = false,
                        clubId = false,
                        memberId = false,
                    },
                    name = "MANUAL_SNAPSHOT",
                    sequence = 7,
                },
                {
                    availability = {
                        canRequestRosterUpdate = false,
                        clubId = false,
                        memberId = false,
                    },
                    name = "MANUAL_SNAPSHOT",
                    sequence = 8,
                },
                {
                    availability = {
                        canRequestRosterUpdate = true,
                        clubId = false,
                        memberId = false,
                    },
                    canRequestRosterUpdate = false,
                    name = "GUILD_ROSTER_UPDATE",
                    sequence = 9,
                },
                {
                    availability = {
                        canRequestRosterUpdate = false,
                        clubId = false,
                        memberId = false,
                    },
                    name = "MARK_LOGOUT_LOGIN",
                    sequence = 10,
                },
                {
                    availability = {
                        canRequestRosterUpdate = false,
                        clubId = false,
                        memberId = false,
                    },
                    name = "PLAYER_LEAVING_WORLD",
                    sequence = 11,
                },
                {
                    availability = {
                        canRequestRosterUpdate = false,
                        clubId = false,
                        memberId = false,
                    },
                    name = "PLAYER_LOGOUT",
                    sequence = 12,
                },
            },
            index = 2,
            observations = {
                {
                    availability = {
                        guildRosterMemberCount = true,
                        guildRosterOnlineCount = true,
                        memberListCount = true,
                    },
                    errors = {
                    },
                    guild = {
                        availability = {
                            clubId = true,
                            memberCount = true,
                            name = true,
                            realm = false,
                        },
                        clubId = "Club-001",
                        memberCount = 56,
                        name = "Guild-001",
                    },
                    guildRosterMemberCount = 56,
                    guildRosterOnlineCount = 3,
                    memberListCount = 56,
                    memberSource = "club",
                    members = {
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-001",
                            name = "First-002 Surname-002",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-002",
                            name = "First-003 Surname-003",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-003",
                            name = "First-004 Surname-004",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-004",
                            name = "First-005 Surname-005",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-005",
                            name = "First-006 Surname-006",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-006",
                            name = "First-007 Surname-007",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-007",
                            name = "First-008 Surname-008",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-008",
                            name = "First-009 Surname-009",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-009",
                            name = "First-010 Surname-010",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-010",
                            name = "First-011 Surname-011",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-011",
                            name = "First-012 Surname-012",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-012",
                            name = "First-013 Surname-013",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-013",
                            name = "First-014 Surname-014",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-014",
                            name = "First-015 Surname-015",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-015",
                            name = "First-016 Surname-016",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-016",
                            name = "First-017 Surname-017",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-017",
                            name = "First-018 Surname-018",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-018",
                            name = "First-019 Surname-013",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-019",
                            name = "First-020 Surname-019",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-020",
                            name = "First-021 Surname-020",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-021",
                            name = "First-022 Surname-021",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-022",
                            name = "First-023 Surname-022",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-023",
                            name = "First-024 Surname-023",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-024",
                            name = "First-025 Surname-024",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-025",
                            name = "First-026 Surname-025",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-026",
                            name = "First-027 Surname-026",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-027",
                            name = "First-028 Surname-010",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-028",
                            name = "First-029 Surname-027",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-029",
                            name = "First-030 Surname-028",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-030",
                            name = "First-031 Surname-011",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-031",
                            name = "First-032 Surname-029",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-032",
                            name = "First-033 Surname-030",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-033",
                            name = "First-034 Surname-014",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-034",
                            name = "First-035 Surname-031",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-035",
                            name = "First-036 Surname-032",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-036",
                            name = "First-037 Surname-033",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-037",
                            name = "First-038 Surname-014",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-038",
                            name = "First-039 Surname-034",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-039",
                            name = "First-040 Surname-035",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-040",
                            name = "First-041 Surname-036",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-041",
                            name = "First-042 Surname-037",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-042",
                            name = "First-043 Surname-038",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-043",
                            name = "First-044 Surname-039",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-044",
                            name = "First-045 Surname-040",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-045",
                            name = "First-046 Surname-021",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-046",
                            name = "First-047 Surname-041",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-047",
                            name = "First-001 Surname-001",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-048",
                            name = "First-048 Surname-042",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-049",
                            name = "First-049 Surname-043",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-050",
                            name = "First-050 Surname-044",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-051",
                            name = "First-051 Surname-045",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-052",
                            name = "First-052 Surname-046",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-053",
                            name = "First-053 Surname-047",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-054",
                            name = "First-054 Surname-048",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-055",
                            name = "First-055 Surname-049",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-056",
                            name = "First-056 Surname-050",
                        },
                    },
                    sequence = 1,
                    trigger = "ADDON_LOADED",
                },
                {
                    availability = {
                        guildRosterMemberCount = true,
                        guildRosterOnlineCount = true,
                        memberListCount = true,
                    },
                    errors = {
                    },
                    guild = {
                        availability = {
                            clubId = true,
                            memberCount = true,
                            name = true,
                            realm = false,
                        },
                        clubId = "Club-001",
                        memberCount = 56,
                        name = "Guild-001",
                    },
                    guildRosterMemberCount = 56,
                    guildRosterOnlineCount = 3,
                    memberListCount = 56,
                    memberSource = "club",
                    members = {
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-001",
                            name = "First-002 Surname-002",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-002",
                            name = "First-003 Surname-003",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-003",
                            name = "First-004 Surname-004",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-004",
                            name = "First-005 Surname-005",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-005",
                            name = "First-006 Surname-006",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-006",
                            name = "First-007 Surname-007",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-007",
                            name = "First-008 Surname-008",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-008",
                            name = "First-009 Surname-009",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-009",
                            name = "First-010 Surname-010",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-010",
                            name = "First-011 Surname-011",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-011",
                            name = "First-012 Surname-012",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-012",
                            name = "First-013 Surname-013",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-013",
                            name = "First-014 Surname-014",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-014",
                            name = "First-015 Surname-015",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-015",
                            name = "First-016 Surname-016",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-016",
                            name = "First-017 Surname-017",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-017",
                            name = "First-018 Surname-018",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-018",
                            name = "First-019 Surname-013",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-019",
                            name = "First-020 Surname-019",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-020",
                            name = "First-021 Surname-020",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-021",
                            name = "First-022 Surname-021",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-022",
                            name = "First-023 Surname-022",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-023",
                            name = "First-024 Surname-023",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-024",
                            name = "First-025 Surname-024",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-025",
                            name = "First-026 Surname-025",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-026",
                            name = "First-027 Surname-026",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-027",
                            name = "First-028 Surname-010",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-028",
                            name = "First-029 Surname-027",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-029",
                            name = "First-030 Surname-028",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-030",
                            name = "First-031 Surname-011",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-031",
                            name = "First-032 Surname-029",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-032",
                            name = "First-033 Surname-030",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-033",
                            name = "First-034 Surname-014",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-034",
                            name = "First-035 Surname-031",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-035",
                            name = "First-036 Surname-032",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-036",
                            name = "First-037 Surname-033",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-037",
                            name = "First-038 Surname-014",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-038",
                            name = "First-039 Surname-034",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-039",
                            name = "First-040 Surname-035",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-040",
                            name = "First-041 Surname-036",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-041",
                            name = "First-042 Surname-037",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-042",
                            name = "First-043 Surname-038",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-043",
                            name = "First-044 Surname-039",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-044",
                            name = "First-045 Surname-040",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-045",
                            name = "First-046 Surname-021",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-046",
                            name = "First-047 Surname-041",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-047",
                            name = "First-001 Surname-001",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-048",
                            name = "First-048 Surname-042",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-049",
                            name = "First-049 Surname-043",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-050",
                            name = "First-050 Surname-044",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-051",
                            name = "First-051 Surname-045",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-052",
                            name = "First-052 Surname-046",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-053",
                            name = "First-053 Surname-047",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-054",
                            name = "First-054 Surname-048",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-055",
                            name = "First-055 Surname-049",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-056",
                            name = "First-056 Surname-050",
                        },
                    },
                    sequence = 2,
                    trigger = "INITIAL_CLUBS_LOADED",
                },
                {
                    availability = {
                        guildRosterMemberCount = true,
                        guildRosterOnlineCount = true,
                        memberListCount = true,
                    },
                    errors = {
                    },
                    guild = {
                        availability = {
                            clubId = true,
                            memberCount = true,
                            name = true,
                            realm = false,
                        },
                        clubId = "Club-001",
                        memberCount = 56,
                        name = "Guild-001",
                    },
                    guildRosterMemberCount = 56,
                    guildRosterOnlineCount = 3,
                    memberListCount = 56,
                    memberSource = "club",
                    members = {
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-001",
                            name = "First-002 Surname-002",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-002",
                            name = "First-003 Surname-003",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-003",
                            name = "First-004 Surname-004",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-004",
                            name = "First-005 Surname-005",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-005",
                            name = "First-006 Surname-006",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-006",
                            name = "First-007 Surname-007",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-007",
                            name = "First-008 Surname-008",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-008",
                            name = "First-009 Surname-009",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-009",
                            name = "First-010 Surname-010",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-010",
                            name = "First-011 Surname-011",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-011",
                            name = "First-012 Surname-012",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-012",
                            name = "First-013 Surname-013",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-013",
                            name = "First-014 Surname-014",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-014",
                            name = "First-015 Surname-015",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-015",
                            name = "First-016 Surname-016",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-016",
                            name = "First-017 Surname-017",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-017",
                            name = "First-018 Surname-018",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-018",
                            name = "First-019 Surname-013",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-019",
                            name = "First-020 Surname-019",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-020",
                            name = "First-021 Surname-020",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-021",
                            name = "First-022 Surname-021",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-022",
                            name = "First-023 Surname-022",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-023",
                            name = "First-024 Surname-023",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-024",
                            name = "First-025 Surname-024",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-025",
                            name = "First-026 Surname-025",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-026",
                            name = "First-027 Surname-026",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-027",
                            name = "First-028 Surname-010",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-028",
                            name = "First-029 Surname-027",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-029",
                            name = "First-030 Surname-028",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-030",
                            name = "First-031 Surname-011",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-031",
                            name = "First-032 Surname-029",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-032",
                            name = "First-033 Surname-030",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-033",
                            name = "First-034 Surname-014",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-034",
                            name = "First-035 Surname-031",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-035",
                            name = "First-036 Surname-032",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-036",
                            name = "First-037 Surname-033",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-037",
                            name = "First-038 Surname-014",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-038",
                            name = "First-039 Surname-034",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-039",
                            name = "First-040 Surname-035",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-040",
                            name = "First-041 Surname-036",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-041",
                            name = "First-042 Surname-037",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-042",
                            name = "First-043 Surname-038",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-043",
                            name = "First-044 Surname-039",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-044",
                            name = "First-045 Surname-040",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-045",
                            name = "First-046 Surname-021",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-046",
                            name = "First-047 Surname-041",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-047",
                            name = "First-001 Surname-001",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-048",
                            name = "First-048 Surname-042",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-049",
                            name = "First-049 Surname-043",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-050",
                            name = "First-050 Surname-044",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-051",
                            name = "First-051 Surname-045",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-052",
                            name = "First-052 Surname-046",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-053",
                            name = "First-053 Surname-047",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-054",
                            name = "First-054 Surname-048",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-055",
                            name = "First-055 Surname-049",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-056",
                            name = "First-056 Surname-050",
                        },
                    },
                    sequence = 3,
                    trigger = "PLAYER_LOGIN",
                },
                {
                    availability = {
                        guildRosterMemberCount = true,
                        guildRosterOnlineCount = true,
                        memberListCount = true,
                    },
                    errors = {
                    },
                    guild = {
                        availability = {
                            clubId = true,
                            memberCount = true,
                            name = true,
                            realm = false,
                        },
                        clubId = "Club-001",
                        memberCount = 56,
                        name = "Guild-001",
                    },
                    guildRosterMemberCount = 56,
                    guildRosterOnlineCount = 3,
                    memberListCount = 56,
                    memberSource = "club",
                    members = {
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-001",
                            name = "First-002 Surname-002",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-002",
                            name = "First-003 Surname-003",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-003",
                            name = "First-004 Surname-004",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-004",
                            name = "First-005 Surname-005",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-005",
                            name = "First-006 Surname-006",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-006",
                            name = "First-007 Surname-007",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-007",
                            name = "First-008 Surname-008",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-008",
                            name = "First-009 Surname-009",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-009",
                            name = "First-010 Surname-010",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-010",
                            name = "First-011 Surname-011",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-011",
                            name = "First-012 Surname-012",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-012",
                            name = "First-013 Surname-013",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-013",
                            name = "First-014 Surname-014",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-014",
                            name = "First-015 Surname-015",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-015",
                            name = "First-016 Surname-016",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-016",
                            name = "First-017 Surname-017",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-017",
                            name = "First-018 Surname-018",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-018",
                            name = "First-019 Surname-013",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-019",
                            name = "First-020 Surname-019",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-020",
                            name = "First-021 Surname-020",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-021",
                            name = "First-022 Surname-021",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-022",
                            name = "First-023 Surname-022",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-023",
                            name = "First-024 Surname-023",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-024",
                            name = "First-025 Surname-024",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-025",
                            name = "First-026 Surname-025",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-026",
                            name = "First-027 Surname-026",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-027",
                            name = "First-028 Surname-010",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-028",
                            name = "First-029 Surname-027",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-029",
                            name = "First-030 Surname-028",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-030",
                            name = "First-031 Surname-011",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-031",
                            name = "First-032 Surname-029",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-032",
                            name = "First-033 Surname-030",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-033",
                            name = "First-034 Surname-014",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-034",
                            name = "First-035 Surname-031",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-035",
                            name = "First-036 Surname-032",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-036",
                            name = "First-037 Surname-033",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-037",
                            name = "First-038 Surname-014",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-038",
                            name = "First-039 Surname-034",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-039",
                            name = "First-040 Surname-035",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-040",
                            name = "First-041 Surname-036",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-041",
                            name = "First-042 Surname-037",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-042",
                            name = "First-043 Surname-038",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-043",
                            name = "First-044 Surname-039",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-044",
                            name = "First-045 Surname-040",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-045",
                            name = "First-046 Surname-021",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-046",
                            name = "First-047 Surname-041",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-047",
                            name = "First-001 Surname-001",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-048",
                            name = "First-048 Surname-042",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-049",
                            name = "First-049 Surname-043",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-050",
                            name = "First-050 Surname-044",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-051",
                            name = "First-051 Surname-045",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-052",
                            name = "First-052 Surname-046",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-053",
                            name = "First-053 Surname-047",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-054",
                            name = "First-054 Surname-048",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-055",
                            name = "First-055 Surname-049",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-056",
                            name = "First-056 Surname-050",
                        },
                    },
                    sequence = 4,
                    trigger = "PLAYER_ENTERING_WORLD",
                },
                {
                    availability = {
                        guildRosterMemberCount = true,
                        guildRosterOnlineCount = true,
                        memberListCount = true,
                    },
                    errors = {
                    },
                    guild = {
                        availability = {
                            clubId = true,
                            memberCount = true,
                            name = true,
                            realm = false,
                        },
                        clubId = "Club-001",
                        memberCount = 56,
                        name = "Guild-001",
                    },
                    guildRosterMemberCount = 56,
                    guildRosterOnlineCount = 3,
                    memberListCount = 56,
                    memberSource = "club",
                    members = {
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-001",
                            name = "First-002 Surname-002",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-002",
                            name = "First-003 Surname-003",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-003",
                            name = "First-004 Surname-004",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-004",
                            name = "First-005 Surname-005",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-005",
                            name = "First-006 Surname-006",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-006",
                            name = "First-007 Surname-007",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-007",
                            name = "First-008 Surname-008",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-008",
                            name = "First-009 Surname-009",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-009",
                            name = "First-010 Surname-010",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-010",
                            name = "First-011 Surname-011",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-011",
                            name = "First-012 Surname-012",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-012",
                            name = "First-013 Surname-013",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-013",
                            name = "First-014 Surname-014",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-014",
                            name = "First-015 Surname-015",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-015",
                            name = "First-016 Surname-016",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-016",
                            name = "First-017 Surname-017",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-017",
                            name = "First-018 Surname-018",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-018",
                            name = "First-019 Surname-013",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-019",
                            name = "First-020 Surname-019",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-020",
                            name = "First-021 Surname-020",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-021",
                            name = "First-022 Surname-021",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-022",
                            name = "First-023 Surname-022",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-023",
                            name = "First-024 Surname-023",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-024",
                            name = "First-025 Surname-024",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-025",
                            name = "First-026 Surname-025",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-026",
                            name = "First-027 Surname-026",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-027",
                            name = "First-028 Surname-010",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-028",
                            name = "First-029 Surname-027",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-029",
                            name = "First-030 Surname-028",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-030",
                            name = "First-031 Surname-011",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-031",
                            name = "First-032 Surname-029",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-032",
                            name = "First-033 Surname-030",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-033",
                            name = "First-034 Surname-014",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-034",
                            name = "First-035 Surname-031",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-035",
                            name = "First-036 Surname-032",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-036",
                            name = "First-037 Surname-033",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-037",
                            name = "First-038 Surname-014",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-038",
                            name = "First-039 Surname-034",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-039",
                            name = "First-040 Surname-035",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-040",
                            name = "First-041 Surname-036",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-041",
                            name = "First-042 Surname-037",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-042",
                            name = "First-043 Surname-038",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-043",
                            name = "First-044 Surname-039",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-044",
                            name = "First-045 Surname-040",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-045",
                            name = "First-046 Surname-021",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-046",
                            name = "First-047 Surname-041",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-047",
                            name = "First-001 Surname-001",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-048",
                            name = "First-048 Surname-042",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-049",
                            name = "First-049 Surname-043",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-050",
                            name = "First-050 Surname-044",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-051",
                            name = "First-051 Surname-045",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-052",
                            name = "First-052 Surname-046",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-053",
                            name = "First-053 Surname-047",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-054",
                            name = "First-054 Surname-048",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-055",
                            name = "First-055 Surname-049",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-056",
                            name = "First-056 Surname-050",
                        },
                    },
                    sequence = 5,
                    trigger = "GUILD_ROSTER_UPDATE",
                },
                {
                    availability = {
                        guildRosterMemberCount = true,
                        guildRosterOnlineCount = true,
                        memberListCount = true,
                    },
                    errors = {
                    },
                    guild = {
                        availability = {
                            clubId = true,
                            memberCount = true,
                            name = true,
                            realm = false,
                        },
                        clubId = "Club-001",
                        memberCount = 56,
                        name = "Guild-001",
                    },
                    guildRosterMemberCount = 56,
                    guildRosterOnlineCount = 3,
                    memberListCount = 56,
                    memberSource = "club",
                    members = {
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-001",
                            name = "First-002 Surname-002",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-002",
                            name = "First-003 Surname-003",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-003",
                            name = "First-004 Surname-004",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-004",
                            name = "First-005 Surname-005",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-005",
                            name = "First-006 Surname-006",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-006",
                            name = "First-007 Surname-007",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-007",
                            name = "First-008 Surname-008",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-008",
                            name = "First-009 Surname-009",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-009",
                            name = "First-010 Surname-010",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-010",
                            name = "First-011 Surname-011",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-011",
                            name = "First-012 Surname-012",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-012",
                            name = "First-013 Surname-013",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-013",
                            name = "First-014 Surname-014",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-014",
                            name = "First-015 Surname-015",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-015",
                            name = "First-016 Surname-016",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-016",
                            name = "First-017 Surname-017",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-017",
                            name = "First-018 Surname-018",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-018",
                            name = "First-019 Surname-013",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-019",
                            name = "First-020 Surname-019",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-020",
                            name = "First-021 Surname-020",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-021",
                            name = "First-022 Surname-021",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-022",
                            name = "First-023 Surname-022",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-023",
                            name = "First-024 Surname-023",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-024",
                            name = "First-025 Surname-024",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-025",
                            name = "First-026 Surname-025",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-026",
                            name = "First-027 Surname-026",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-027",
                            name = "First-028 Surname-010",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-028",
                            name = "First-029 Surname-027",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-029",
                            name = "First-030 Surname-028",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-030",
                            name = "First-031 Surname-011",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-031",
                            name = "First-032 Surname-029",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-032",
                            name = "First-033 Surname-030",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-033",
                            name = "First-034 Surname-014",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-034",
                            name = "First-035 Surname-031",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-035",
                            name = "First-036 Surname-032",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-036",
                            name = "First-037 Surname-033",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-037",
                            name = "First-038 Surname-014",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-038",
                            name = "First-039 Surname-034",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-039",
                            name = "First-040 Surname-035",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-040",
                            name = "First-041 Surname-036",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-041",
                            name = "First-042 Surname-037",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-042",
                            name = "First-043 Surname-038",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-043",
                            name = "First-044 Surname-039",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-044",
                            name = "First-045 Surname-040",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-045",
                            name = "First-046 Surname-021",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-046",
                            name = "First-047 Surname-041",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-047",
                            name = "First-001 Surname-001",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-048",
                            name = "First-048 Surname-042",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-049",
                            name = "First-049 Surname-043",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-050",
                            name = "First-050 Surname-044",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-051",
                            name = "First-051 Surname-045",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-052",
                            name = "First-052 Surname-046",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-053",
                            name = "First-053 Surname-047",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-054",
                            name = "First-054 Surname-048",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-055",
                            name = "First-055 Surname-049",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-056",
                            name = "First-056 Surname-050",
                        },
                    },
                    sequence = 6,
                    trigger = "GUILD_ROSTER_UPDATE",
                },
                {
                    availability = {
                        guildRosterMemberCount = true,
                        guildRosterOnlineCount = true,
                        memberListCount = true,
                    },
                    errors = {
                    },
                    guild = {
                        availability = {
                            clubId = true,
                            memberCount = true,
                            name = true,
                            realm = false,
                        },
                        clubId = "Club-001",
                        memberCount = 56,
                        name = "Guild-001",
                    },
                    guildRosterMemberCount = 56,
                    guildRosterOnlineCount = 3,
                    memberListCount = 56,
                    memberSource = "club",
                    members = {
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-001",
                            name = "First-002 Surname-002",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-002",
                            name = "First-003 Surname-003",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-003",
                            name = "First-004 Surname-004",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-004",
                            name = "First-005 Surname-005",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-005",
                            name = "First-006 Surname-006",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-006",
                            name = "First-007 Surname-007",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-007",
                            name = "First-008 Surname-008",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-008",
                            name = "First-009 Surname-009",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-009",
                            name = "First-010 Surname-010",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-010",
                            name = "First-011 Surname-011",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-011",
                            name = "First-012 Surname-012",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-012",
                            name = "First-013 Surname-013",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-013",
                            name = "First-014 Surname-014",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-014",
                            name = "First-015 Surname-015",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-015",
                            name = "First-016 Surname-016",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-016",
                            name = "First-017 Surname-017",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-017",
                            name = "First-018 Surname-018",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-018",
                            name = "First-019 Surname-013",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-019",
                            name = "First-020 Surname-019",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-020",
                            name = "First-021 Surname-020",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-021",
                            name = "First-022 Surname-021",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-022",
                            name = "First-023 Surname-022",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-023",
                            name = "First-024 Surname-023",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-024",
                            name = "First-025 Surname-024",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-025",
                            name = "First-026 Surname-025",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-026",
                            name = "First-027 Surname-026",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-027",
                            name = "First-028 Surname-010",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-028",
                            name = "First-029 Surname-027",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-029",
                            name = "First-030 Surname-028",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-030",
                            name = "First-031 Surname-011",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-031",
                            name = "First-032 Surname-029",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-032",
                            name = "First-033 Surname-030",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-033",
                            name = "First-034 Surname-014",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-034",
                            name = "First-035 Surname-031",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-035",
                            name = "First-036 Surname-032",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-036",
                            name = "First-037 Surname-033",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-037",
                            name = "First-038 Surname-014",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-038",
                            name = "First-039 Surname-034",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-039",
                            name = "First-040 Surname-035",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-040",
                            name = "First-041 Surname-036",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-041",
                            name = "First-042 Surname-037",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-042",
                            name = "First-043 Surname-038",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-043",
                            name = "First-044 Surname-039",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-044",
                            name = "First-045 Surname-040",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-045",
                            name = "First-046 Surname-021",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-046",
                            name = "First-047 Surname-041",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-047",
                            name = "First-001 Surname-001",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-048",
                            name = "First-048 Surname-042",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-049",
                            name = "First-049 Surname-043",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-050",
                            name = "First-050 Surname-044",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-051",
                            name = "First-051 Surname-045",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-052",
                            name = "First-052 Surname-046",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-053",
                            name = "First-053 Surname-047",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-054",
                            name = "First-054 Surname-048",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-055",
                            name = "First-055 Surname-049",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-056",
                            name = "First-056 Surname-050",
                        },
                    },
                    sequence = 7,
                    trigger = "MANUAL_SNAPSHOT",
                },
                {
                    availability = {
                        guildRosterMemberCount = true,
                        guildRosterOnlineCount = true,
                        memberListCount = true,
                    },
                    errors = {
                    },
                    guild = {
                        availability = {
                            clubId = true,
                            memberCount = true,
                            name = true,
                            realm = false,
                        },
                        clubId = "Club-001",
                        memberCount = 56,
                        name = "Guild-001",
                    },
                    guildRosterMemberCount = 56,
                    guildRosterOnlineCount = 3,
                    memberListCount = 56,
                    memberSource = "club",
                    members = {
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-001",
                            name = "First-002 Surname-002",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-002",
                            name = "First-003 Surname-003",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-003",
                            name = "First-004 Surname-004",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-004",
                            name = "First-005 Surname-005",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-005",
                            name = "First-006 Surname-006",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-006",
                            name = "First-007 Surname-007",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-007",
                            name = "First-008 Surname-008",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-008",
                            name = "First-009 Surname-009",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-009",
                            name = "First-010 Surname-010",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-010",
                            name = "First-011 Surname-011",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-011",
                            name = "First-012 Surname-012",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-012",
                            name = "First-013 Surname-013",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-013",
                            name = "First-014 Surname-014",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-014",
                            name = "First-015 Surname-015",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-015",
                            name = "First-016 Surname-016",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-016",
                            name = "First-017 Surname-017",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-017",
                            name = "First-018 Surname-018",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-018",
                            name = "First-019 Surname-013",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-019",
                            name = "First-020 Surname-019",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-020",
                            name = "First-021 Surname-020",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-021",
                            name = "First-022 Surname-021",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-022",
                            name = "First-023 Surname-022",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-023",
                            name = "First-024 Surname-023",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-024",
                            name = "First-025 Surname-024",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-025",
                            name = "First-026 Surname-025",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-026",
                            name = "First-027 Surname-026",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-027",
                            name = "First-028 Surname-010",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-028",
                            name = "First-029 Surname-027",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-029",
                            name = "First-030 Surname-028",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-030",
                            name = "First-031 Surname-011",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-031",
                            name = "First-032 Surname-029",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-032",
                            name = "First-033 Surname-030",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-033",
                            name = "First-034 Surname-014",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-034",
                            name = "First-035 Surname-031",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-035",
                            name = "First-036 Surname-032",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-036",
                            name = "First-037 Surname-033",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-037",
                            name = "First-038 Surname-014",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-038",
                            name = "First-039 Surname-034",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-039",
                            name = "First-040 Surname-035",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-040",
                            name = "First-041 Surname-036",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-041",
                            name = "First-042 Surname-037",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-042",
                            name = "First-043 Surname-038",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-043",
                            name = "First-044 Surname-039",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-044",
                            name = "First-045 Surname-040",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-045",
                            name = "First-046 Surname-021",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-046",
                            name = "First-047 Surname-041",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-047",
                            name = "First-001 Surname-001",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-048",
                            name = "First-048 Surname-042",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-049",
                            name = "First-049 Surname-043",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-050",
                            name = "First-050 Surname-044",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-051",
                            name = "First-051 Surname-045",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-052",
                            name = "First-052 Surname-046",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-053",
                            name = "First-053 Surname-047",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-054",
                            name = "First-054 Surname-048",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-055",
                            name = "First-055 Surname-049",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-056",
                            name = "First-056 Surname-050",
                        },
                    },
                    sequence = 8,
                    trigger = "MANUAL_SNAPSHOT",
                },
                {
                    availability = {
                        guildRosterMemberCount = true,
                        guildRosterOnlineCount = true,
                        memberListCount = true,
                    },
                    errors = {
                    },
                    guild = {
                        availability = {
                            clubId = true,
                            memberCount = true,
                            name = true,
                            realm = false,
                        },
                        clubId = "Club-001",
                        memberCount = 56,
                        name = "Guild-001",
                    },
                    guildRosterMemberCount = 56,
                    guildRosterOnlineCount = 3,
                    memberListCount = 56,
                    memberSource = "club",
                    members = {
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-001",
                            name = "First-002 Surname-002",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-002",
                            name = "First-003 Surname-003",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-003",
                            name = "First-004 Surname-004",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-004",
                            name = "First-005 Surname-005",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-005",
                            name = "First-006 Surname-006",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-006",
                            name = "First-007 Surname-007",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-007",
                            name = "First-008 Surname-008",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-008",
                            name = "First-009 Surname-009",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-009",
                            name = "First-010 Surname-010",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-010",
                            name = "First-011 Surname-011",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-011",
                            name = "First-012 Surname-012",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-012",
                            name = "First-013 Surname-013",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-013",
                            name = "First-014 Surname-014",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-014",
                            name = "First-015 Surname-015",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-015",
                            name = "First-016 Surname-016",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-016",
                            name = "First-017 Surname-017",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-017",
                            name = "First-018 Surname-018",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-018",
                            name = "First-019 Surname-013",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-019",
                            name = "First-020 Surname-019",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-020",
                            name = "First-021 Surname-020",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-021",
                            name = "First-022 Surname-021",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-022",
                            name = "First-023 Surname-022",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-023",
                            name = "First-024 Surname-023",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-024",
                            name = "First-025 Surname-024",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-025",
                            name = "First-026 Surname-025",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-026",
                            name = "First-027 Surname-026",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-027",
                            name = "First-028 Surname-010",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-028",
                            name = "First-029 Surname-027",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-029",
                            name = "First-030 Surname-028",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-030",
                            name = "First-031 Surname-011",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-031",
                            name = "First-032 Surname-029",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-032",
                            name = "First-033 Surname-030",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-033",
                            name = "First-034 Surname-014",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-034",
                            name = "First-035 Surname-031",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-035",
                            name = "First-036 Surname-032",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-036",
                            name = "First-037 Surname-033",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-037",
                            name = "First-038 Surname-014",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-038",
                            name = "First-039 Surname-034",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-039",
                            name = "First-040 Surname-035",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-040",
                            name = "First-041 Surname-036",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-041",
                            name = "First-042 Surname-037",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-042",
                            name = "First-043 Surname-038",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-043",
                            name = "First-044 Surname-039",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-044",
                            name = "First-045 Surname-040",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-045",
                            name = "First-046 Surname-021",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-046",
                            name = "First-047 Surname-041",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-047",
                            name = "First-001 Surname-001",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-048",
                            name = "First-048 Surname-042",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-049",
                            name = "First-049 Surname-043",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-050",
                            name = "First-050 Surname-044",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-051",
                            name = "First-051 Surname-045",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-052",
                            name = "First-052 Surname-046",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-053",
                            name = "First-053 Surname-047",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-054",
                            name = "First-054 Surname-048",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-055",
                            name = "First-055 Surname-049",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-056",
                            name = "First-056 Surname-050",
                        },
                    },
                    sequence = 9,
                    trigger = "GUILD_ROSTER_UPDATE",
                },
                {
                    availability = {
                        guildRosterMemberCount = true,
                        guildRosterOnlineCount = true,
                        memberListCount = true,
                    },
                    errors = {
                        "GET_GUILD_ROSTER_INFO_INCOMPLETE",
                    },
                    guild = {
                        availability = {
                            clubId = true,
                            memberCount = true,
                            name = true,
                            realm = false,
                        },
                        clubId = "Club-001",
                        memberCount = 56,
                        name = "Guild-001",
                    },
                    guildRosterMemberCount = 56,
                    guildRosterOnlineCount = 3,
                    memberListCount = 56,
                    memberSource = "club",
                    members = {
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-001",
                            name = "First-002 Surname-002",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-002",
                            name = "First-003 Surname-003",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-003",
                            name = "First-004 Surname-004",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-004",
                            name = "First-005 Surname-005",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-005",
                            name = "First-006 Surname-006",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-006",
                            name = "First-007 Surname-007",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-007",
                            name = "First-008 Surname-008",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-008",
                            name = "First-009 Surname-009",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-009",
                            name = "First-010 Surname-010",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-010",
                            name = "First-011 Surname-011",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-011",
                            name = "First-012 Surname-012",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-012",
                            name = "First-013 Surname-013",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-013",
                            name = "First-014 Surname-014",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-014",
                            name = "First-015 Surname-015",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-015",
                            name = "First-016 Surname-016",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-016",
                            name = "First-017 Surname-017",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-017",
                            name = "First-018 Surname-018",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-018",
                            name = "First-019 Surname-013",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-019",
                            name = "First-020 Surname-019",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-020",
                            name = "First-021 Surname-020",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-021",
                            name = "First-022 Surname-021",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-022",
                            name = "First-023 Surname-022",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-023",
                            name = "First-024 Surname-023",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-024",
                            name = "First-025 Surname-024",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-025",
                            name = "First-026 Surname-025",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-026",
                            name = "First-027 Surname-026",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-027",
                            name = "First-028 Surname-010",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-028",
                            name = "First-029 Surname-027",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-029",
                            name = "First-030 Surname-028",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-030",
                            name = "First-031 Surname-011",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-031",
                            name = "First-032 Surname-029",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-032",
                            name = "First-033 Surname-030",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-033",
                            name = "First-034 Surname-014",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-034",
                            name = "First-035 Surname-031",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-035",
                            name = "First-036 Surname-032",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-036",
                            name = "First-037 Surname-033",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-037",
                            name = "First-038 Surname-014",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-038",
                            name = "First-039 Surname-034",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-039",
                            name = "First-040 Surname-035",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-040",
                            name = "First-041 Surname-036",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-041",
                            name = "First-042 Surname-037",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-042",
                            name = "First-043 Surname-038",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-043",
                            name = "First-044 Surname-039",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-044",
                            name = "First-045 Surname-040",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-045",
                            name = "First-046 Surname-021",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-046",
                            name = "First-047 Surname-041",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-047",
                            name = "First-001 Surname-001",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-048",
                            name = "First-048 Surname-042",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-049",
                            name = "First-049 Surname-043",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-050",
                            name = "First-050 Surname-044",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-051",
                            name = "First-051 Surname-045",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-052",
                            name = "First-052 Surname-046",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-053",
                            name = "First-053 Surname-047",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-054",
                            name = "First-054 Surname-048",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-055",
                            name = "First-055 Surname-049",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-056",
                            name = "First-056 Surname-050",
                        },
                    },
                    sequence = 10,
                    trigger = "PLAYER_LEAVING_WORLD",
                },
                {
                    availability = {
                        guildRosterMemberCount = true,
                        guildRosterOnlineCount = true,
                        memberListCount = true,
                    },
                    errors = {
                        "GET_GUILD_ROSTER_INFO_INCOMPLETE",
                    },
                    guild = {
                        availability = {
                            clubId = true,
                            memberCount = true,
                            name = true,
                            realm = false,
                        },
                        clubId = "Club-001",
                        memberCount = 56,
                        name = "Guild-001",
                    },
                    guildRosterMemberCount = 56,
                    guildRosterOnlineCount = 3,
                    memberListCount = 56,
                    memberSource = "club",
                    members = {
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-001",
                            name = "First-002 Surname-002",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-002",
                            name = "First-003 Surname-003",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-003",
                            name = "First-004 Surname-004",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-004",
                            name = "First-005 Surname-005",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-005",
                            name = "First-006 Surname-006",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-006",
                            name = "First-007 Surname-007",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-007",
                            name = "First-008 Surname-008",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-008",
                            name = "First-009 Surname-009",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-009",
                            name = "First-010 Surname-010",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-010",
                            name = "First-011 Surname-011",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-011",
                            name = "First-012 Surname-012",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-012",
                            name = "First-013 Surname-013",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-013",
                            name = "First-014 Surname-014",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-014",
                            name = "First-015 Surname-015",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-015",
                            name = "First-016 Surname-016",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-016",
                            name = "First-017 Surname-017",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-017",
                            name = "First-018 Surname-018",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-018",
                            name = "First-019 Surname-013",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-019",
                            name = "First-020 Surname-019",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-020",
                            name = "First-021 Surname-020",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-021",
                            name = "First-022 Surname-021",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-022",
                            name = "First-023 Surname-022",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-023",
                            name = "First-024 Surname-023",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-024",
                            name = "First-025 Surname-024",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-025",
                            name = "First-026 Surname-025",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-026",
                            name = "First-027 Surname-026",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-027",
                            name = "First-028 Surname-010",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-028",
                            name = "First-029 Surname-027",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-029",
                            name = "First-030 Surname-028",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-030",
                            name = "First-031 Surname-011",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-031",
                            name = "First-032 Surname-029",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-032",
                            name = "First-033 Surname-030",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-033",
                            name = "First-034 Surname-014",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-034",
                            name = "First-035 Surname-031",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-035",
                            name = "First-036 Surname-032",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-036",
                            name = "First-037 Surname-033",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-037",
                            name = "First-038 Surname-014",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-038",
                            name = "First-039 Surname-034",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-039",
                            name = "First-040 Surname-035",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-040",
                            name = "First-041 Surname-036",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-041",
                            name = "First-042 Surname-037",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-042",
                            name = "First-043 Surname-038",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-043",
                            name = "First-044 Surname-039",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-044",
                            name = "First-045 Surname-040",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-045",
                            name = "First-046 Surname-021",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-046",
                            name = "First-047 Surname-041",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-047",
                            name = "First-001 Surname-001",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-048",
                            name = "First-048 Surname-042",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-049",
                            name = "First-049 Surname-043",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-050",
                            name = "First-050 Surname-044",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-051",
                            name = "First-051 Surname-045",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-052",
                            name = "First-052 Surname-046",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-053",
                            name = "First-053 Surname-047",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-054",
                            name = "First-054 Surname-048",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-055",
                            name = "First-055 Surname-049",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-056",
                            name = "First-056 Surname-050",
                        },
                    },
                    sequence = 11,
                    trigger = "PLAYER_LOGOUT",
                },
            },
            runtime = {
                availability = {
                    build = true,
                    interface = true,
                    normalizedRealmName = true,
                    playerName = true,
                    playerRealm = true,
                    productId = true,
                    realmName = true,
                    region = true,
                    version = true,
                },
                build = "70888",
                errors = {
                },
                interface = 16001,
                normalizedRealmName = "Realm-002",
                playerName = "First-001 Surname-001",
                playerRealm = "Realm-003",
                productId = 18,
                realmName = "Realm-001",
                region = "US",
                version = "1.60.1",
            },
        },
        {
            boundary = "logout-login",
            events = {
                {
                    availability = {
                        canRequestRosterUpdate = false,
                        clubId = false,
                        memberId = false,
                    },
                    name = "ADDON_LOADED",
                    sequence = 1,
                },
                {
                    availability = {
                        canRequestRosterUpdate = true,
                        clubId = false,
                        memberId = false,
                    },
                    canRequestRosterUpdate = false,
                    name = "GUILD_ROSTER_UPDATE",
                    sequence = 2,
                },
                {
                    availability = {
                        canRequestRosterUpdate = false,
                        clubId = false,
                        memberId = false,
                    },
                    name = "PLAYER_GUILD_UPDATE",
                    sequence = 3,
                },
                {
                    availability = {
                        canRequestRosterUpdate = false,
                        clubId = false,
                        memberId = false,
                    },
                    name = "PLAYER_LOGIN",
                    sequence = 4,
                },
                {
                    availability = {
                        canRequestRosterUpdate = false,
                        clubId = false,
                        memberId = false,
                    },
                    name = "PLAYER_ENTERING_WORLD",
                    sequence = 5,
                },
                {
                    availability = {
                        canRequestRosterUpdate = true,
                        clubId = false,
                        memberId = false,
                    },
                    canRequestRosterUpdate = true,
                    name = "GUILD_ROSTER_UPDATE",
                    sequence = 6,
                },
                {
                    availability = {
                        canRequestRosterUpdate = true,
                        clubId = false,
                        memberId = false,
                    },
                    canRequestRosterUpdate = false,
                    name = "GUILD_ROSTER_UPDATE",
                    sequence = 7,
                },
                {
                    availability = {
                        canRequestRosterUpdate = false,
                        clubId = false,
                        memberId = false,
                    },
                    name = "PLAYER_GUILD_UPDATE",
                    sequence = 8,
                },
                {
                    availability = {
                        canRequestRosterUpdate = true,
                        clubId = false,
                        memberId = false,
                    },
                    canRequestRosterUpdate = false,
                    name = "GUILD_ROSTER_UPDATE",
                    sequence = 9,
                },
                {
                    availability = {
                        canRequestRosterUpdate = true,
                        clubId = false,
                        memberId = false,
                    },
                    canRequestRosterUpdate = false,
                    name = "GUILD_ROSTER_UPDATE",
                    sequence = 10,
                },
                {
                    availability = {
                        canRequestRosterUpdate = true,
                        clubId = false,
                        memberId = false,
                    },
                    canRequestRosterUpdate = false,
                    name = "GUILD_ROSTER_UPDATE",
                    sequence = 11,
                },
                {
                    availability = {
                        canRequestRosterUpdate = false,
                        clubId = true,
                        memberId = false,
                    },
                    clubId = "Club-001",
                    name = "CLUB_MEMBERS_UPDATED",
                    sequence = 12,
                },
                {
                    availability = {
                        canRequestRosterUpdate = false,
                        clubId = false,
                        memberId = false,
                    },
                    name = "INITIAL_CLUBS_LOADED",
                    sequence = 13,
                },
                {
                    availability = {
                        canRequestRosterUpdate = false,
                        clubId = false,
                        memberId = false,
                    },
                    name = "MANUAL_SNAPSHOT",
                    sequence = 14,
                },
                {
                    availability = {
                        canRequestRosterUpdate = true,
                        clubId = false,
                        memberId = false,
                    },
                    canRequestRosterUpdate = false,
                    name = "GUILD_ROSTER_UPDATE",
                    sequence = 15,
                },
                {
                    availability = {
                        canRequestRosterUpdate = false,
                        clubId = false,
                        memberId = false,
                    },
                    name = "MARK_COLD_RESTART",
                    sequence = 16,
                },
                {
                    availability = {
                        canRequestRosterUpdate = false,
                        clubId = false,
                        memberId = false,
                    },
                    name = "PLAYER_LEAVING_WORLD",
                    sequence = 17,
                },
                {
                    availability = {
                        canRequestRosterUpdate = false,
                        clubId = false,
                        memberId = false,
                    },
                    name = "PLAYER_LOGOUT",
                    sequence = 18,
                },
            },
            index = 3,
            observations = {
                {
                    availability = {
                        guildRosterMemberCount = true,
                        guildRosterOnlineCount = true,
                        memberListCount = false,
                    },
                    errors = {
                        "GET_GUILD_CLUB_ID_UNAVAILABLE",
                    },
                    guild = {
                        availability = {
                            clubId = false,
                            memberCount = false,
                            name = false,
                            realm = false,
                        },
                    },
                    guildRosterMemberCount = 0,
                    guildRosterOnlineCount = 0,
                    memberSource = "guild-roster",
                    members = {
                    },
                    sequence = 1,
                    trigger = "ADDON_LOADED",
                },
                {
                    availability = {
                        guildRosterMemberCount = true,
                        guildRosterOnlineCount = true,
                        memberListCount = false,
                    },
                    errors = {
                        "GET_GUILD_CLUB_ID_UNAVAILABLE",
                    },
                    guild = {
                        availability = {
                            clubId = false,
                            memberCount = false,
                            name = false,
                            realm = false,
                        },
                    },
                    guildRosterMemberCount = 0,
                    guildRosterOnlineCount = 0,
                    memberSource = "guild-roster",
                    members = {
                    },
                    sequence = 2,
                    trigger = "GUILD_ROSTER_UPDATE",
                },
                {
                    availability = {
                        guildRosterMemberCount = true,
                        guildRosterOnlineCount = true,
                        memberListCount = false,
                    },
                    errors = {
                        "GET_GUILD_CLUB_ID_UNAVAILABLE",
                    },
                    guild = {
                        availability = {
                            clubId = false,
                            memberCount = false,
                            name = false,
                            realm = false,
                        },
                    },
                    guildRosterMemberCount = 0,
                    guildRosterOnlineCount = 0,
                    memberSource = "guild-roster",
                    members = {
                    },
                    sequence = 3,
                    trigger = "PLAYER_GUILD_UPDATE",
                },
                {
                    availability = {
                        guildRosterMemberCount = true,
                        guildRosterOnlineCount = true,
                        memberListCount = false,
                    },
                    errors = {
                        "GET_GUILD_CLUB_ID_UNAVAILABLE",
                    },
                    guild = {
                        availability = {
                            clubId = false,
                            memberCount = false,
                            name = false,
                            realm = false,
                        },
                    },
                    guildRosterMemberCount = 0,
                    guildRosterOnlineCount = 0,
                    memberSource = "guild-roster",
                    members = {
                    },
                    sequence = 4,
                    trigger = "PLAYER_LOGIN",
                },
                {
                    availability = {
                        guildRosterMemberCount = true,
                        guildRosterOnlineCount = true,
                        memberListCount = false,
                    },
                    errors = {
                        "GET_GUILD_CLUB_ID_UNAVAILABLE",
                    },
                    guild = {
                        availability = {
                            clubId = false,
                            memberCount = false,
                            name = false,
                            realm = false,
                        },
                    },
                    guildRosterMemberCount = 0,
                    guildRosterOnlineCount = 0,
                    memberSource = "guild-roster",
                    members = {
                    },
                    sequence = 5,
                    trigger = "PLAYER_ENTERING_WORLD",
                },
                {
                    availability = {
                        guildRosterMemberCount = true,
                        guildRosterOnlineCount = true,
                        memberListCount = false,
                    },
                    errors = {
                        "GET_GUILD_CLUB_ID_UNAVAILABLE",
                    },
                    guild = {
                        availability = {
                            clubId = false,
                            memberCount = false,
                            name = false,
                            realm = false,
                        },
                    },
                    guildRosterMemberCount = 0,
                    guildRosterOnlineCount = 0,
                    memberSource = "guild-roster",
                    members = {
                    },
                    sequence = 6,
                    trigger = "GUILD_ROSTER_UPDATE",
                },
                {
                    availability = {
                        guildRosterMemberCount = true,
                        guildRosterOnlineCount = true,
                        memberListCount = false,
                    },
                    errors = {
                        "GET_GUILD_CLUB_ID_UNAVAILABLE",
                    },
                    guild = {
                        availability = {
                            clubId = false,
                            memberCount = false,
                            name = false,
                            realm = false,
                        },
                    },
                    guildRosterMemberCount = 56,
                    guildRosterOnlineCount = 3,
                    memberSource = "guild-roster",
                    members = {
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-052",
                            name = "First-052 Surname-046",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-011",
                            name = "First-012 Surname-012",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-047",
                            name = "First-001 Surname-001",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-034",
                            name = "First-035 Surname-031",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-029",
                            name = "First-030 Surname-028",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-041",
                            name = "First-042 Surname-037",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-028",
                            name = "First-029 Surname-027",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-046",
                            name = "First-047 Surname-041",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-033",
                            name = "First-034 Surname-014",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-021",
                            name = "First-022 Surname-021",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-022",
                            name = "First-023 Surname-022",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-016",
                            name = "First-017 Surname-017",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-040",
                            name = "First-041 Surname-036",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-056",
                            name = "First-056 Surname-050",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-027",
                            name = "First-028 Surname-010",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-006",
                            name = "First-007 Surname-007",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-035",
                            name = "First-036 Surname-032",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-017",
                            name = "First-018 Surname-018",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-015",
                            name = "First-016 Surname-016",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-010",
                            name = "First-011 Surname-011",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-007",
                            name = "First-008 Surname-008",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-025",
                            name = "First-026 Surname-025",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-051",
                            name = "First-051 Surname-045",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-045",
                            name = "First-046 Surname-021",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-024",
                            name = "First-025 Surname-024",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-013",
                            name = "First-014 Surname-014",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-050",
                            name = "First-050 Surname-044",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-049",
                            name = "First-049 Surname-043",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-003",
                            name = "First-004 Surname-004",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-039",
                            name = "First-040 Surname-035",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-012",
                            name = "First-013 Surname-013",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-018",
                            name = "First-019 Surname-013",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-032",
                            name = "First-033 Surname-030",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-031",
                            name = "First-032 Surname-029",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-055",
                            name = "First-055 Surname-049",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-002",
                            name = "First-003 Surname-003",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-014",
                            name = "First-015 Surname-015",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-004",
                            name = "First-005 Surname-005",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-043",
                            name = "First-044 Surname-039",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-054",
                            name = "First-054 Surname-048",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-038",
                            name = "First-039 Surname-034",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-044",
                            name = "First-045 Surname-040",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-053",
                            name = "First-053 Surname-047",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-030",
                            name = "First-031 Surname-011",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-023",
                            name = "First-024 Surname-023",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-005",
                            name = "First-006 Surname-006",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-008",
                            name = "First-009 Surname-009",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-001",
                            name = "First-002 Surname-002",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-037",
                            name = "First-038 Surname-014",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-009",
                            name = "First-010 Surname-010",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-026",
                            name = "First-027 Surname-026",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-042",
                            name = "First-043 Surname-038",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-048",
                            name = "First-048 Surname-042",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-036",
                            name = "First-037 Surname-033",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-020",
                            name = "First-021 Surname-020",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-019",
                            name = "First-020 Surname-019",
                        },
                    },
                    sequence = 7,
                    trigger = "GUILD_ROSTER_UPDATE",
                },
                {
                    availability = {
                        guildRosterMemberCount = true,
                        guildRosterOnlineCount = true,
                        memberListCount = false,
                    },
                    errors = {
                        "GET_GUILD_CLUB_ID_UNAVAILABLE",
                    },
                    guild = {
                        availability = {
                            clubId = false,
                            memberCount = false,
                            name = true,
                            realm = false,
                        },
                        name = "Guild-001",
                    },
                    guildRosterMemberCount = 56,
                    guildRosterOnlineCount = 3,
                    memberSource = "guild-roster",
                    members = {
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-052",
                            name = "First-052 Surname-046",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-011",
                            name = "First-012 Surname-012",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-047",
                            name = "First-001 Surname-001",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-034",
                            name = "First-035 Surname-031",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-029",
                            name = "First-030 Surname-028",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-041",
                            name = "First-042 Surname-037",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-028",
                            name = "First-029 Surname-027",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-046",
                            name = "First-047 Surname-041",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-033",
                            name = "First-034 Surname-014",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-021",
                            name = "First-022 Surname-021",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-022",
                            name = "First-023 Surname-022",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-016",
                            name = "First-017 Surname-017",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-040",
                            name = "First-041 Surname-036",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-056",
                            name = "First-056 Surname-050",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-027",
                            name = "First-028 Surname-010",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-006",
                            name = "First-007 Surname-007",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-035",
                            name = "First-036 Surname-032",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-017",
                            name = "First-018 Surname-018",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-015",
                            name = "First-016 Surname-016",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-010",
                            name = "First-011 Surname-011",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-007",
                            name = "First-008 Surname-008",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-025",
                            name = "First-026 Surname-025",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-051",
                            name = "First-051 Surname-045",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-045",
                            name = "First-046 Surname-021",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-024",
                            name = "First-025 Surname-024",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-013",
                            name = "First-014 Surname-014",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-050",
                            name = "First-050 Surname-044",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-049",
                            name = "First-049 Surname-043",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-003",
                            name = "First-004 Surname-004",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-039",
                            name = "First-040 Surname-035",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-012",
                            name = "First-013 Surname-013",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-018",
                            name = "First-019 Surname-013",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-032",
                            name = "First-033 Surname-030",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-031",
                            name = "First-032 Surname-029",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-055",
                            name = "First-055 Surname-049",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-002",
                            name = "First-003 Surname-003",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-014",
                            name = "First-015 Surname-015",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-004",
                            name = "First-005 Surname-005",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-043",
                            name = "First-044 Surname-039",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-054",
                            name = "First-054 Surname-048",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-038",
                            name = "First-039 Surname-034",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-044",
                            name = "First-045 Surname-040",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-053",
                            name = "First-053 Surname-047",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-030",
                            name = "First-031 Surname-011",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-023",
                            name = "First-024 Surname-023",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-005",
                            name = "First-006 Surname-006",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-008",
                            name = "First-009 Surname-009",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-001",
                            name = "First-002 Surname-002",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-037",
                            name = "First-038 Surname-014",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-009",
                            name = "First-010 Surname-010",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-026",
                            name = "First-027 Surname-026",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-042",
                            name = "First-043 Surname-038",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-048",
                            name = "First-048 Surname-042",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-036",
                            name = "First-037 Surname-033",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-020",
                            name = "First-021 Surname-020",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-019",
                            name = "First-020 Surname-019",
                        },
                    },
                    sequence = 8,
                    trigger = "PLAYER_GUILD_UPDATE",
                },
                {
                    availability = {
                        guildRosterMemberCount = true,
                        guildRosterOnlineCount = true,
                        memberListCount = false,
                    },
                    errors = {
                        "GET_GUILD_CLUB_ID_UNAVAILABLE",
                    },
                    guild = {
                        availability = {
                            clubId = false,
                            memberCount = false,
                            name = true,
                            realm = false,
                        },
                        name = "Guild-001",
                    },
                    guildRosterMemberCount = 56,
                    guildRosterOnlineCount = 3,
                    memberSource = "guild-roster",
                    members = {
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-052",
                            name = "First-052 Surname-046",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-011",
                            name = "First-012 Surname-012",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-047",
                            name = "First-001 Surname-001",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-034",
                            name = "First-035 Surname-031",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-029",
                            name = "First-030 Surname-028",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-041",
                            name = "First-042 Surname-037",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-028",
                            name = "First-029 Surname-027",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-046",
                            name = "First-047 Surname-041",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-033",
                            name = "First-034 Surname-014",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-021",
                            name = "First-022 Surname-021",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-022",
                            name = "First-023 Surname-022",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-016",
                            name = "First-017 Surname-017",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-040",
                            name = "First-041 Surname-036",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-056",
                            name = "First-056 Surname-050",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-027",
                            name = "First-028 Surname-010",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-006",
                            name = "First-007 Surname-007",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-035",
                            name = "First-036 Surname-032",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-017",
                            name = "First-018 Surname-018",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-015",
                            name = "First-016 Surname-016",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-010",
                            name = "First-011 Surname-011",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-007",
                            name = "First-008 Surname-008",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-025",
                            name = "First-026 Surname-025",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-051",
                            name = "First-051 Surname-045",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-045",
                            name = "First-046 Surname-021",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-024",
                            name = "First-025 Surname-024",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-013",
                            name = "First-014 Surname-014",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-050",
                            name = "First-050 Surname-044",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-049",
                            name = "First-049 Surname-043",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-003",
                            name = "First-004 Surname-004",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-039",
                            name = "First-040 Surname-035",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-012",
                            name = "First-013 Surname-013",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-018",
                            name = "First-019 Surname-013",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-032",
                            name = "First-033 Surname-030",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-031",
                            name = "First-032 Surname-029",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-055",
                            name = "First-055 Surname-049",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-002",
                            name = "First-003 Surname-003",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-014",
                            name = "First-015 Surname-015",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-004",
                            name = "First-005 Surname-005",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-043",
                            name = "First-044 Surname-039",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-054",
                            name = "First-054 Surname-048",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-038",
                            name = "First-039 Surname-034",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-044",
                            name = "First-045 Surname-040",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-053",
                            name = "First-053 Surname-047",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-030",
                            name = "First-031 Surname-011",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-023",
                            name = "First-024 Surname-023",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-005",
                            name = "First-006 Surname-006",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-008",
                            name = "First-009 Surname-009",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-001",
                            name = "First-002 Surname-002",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-037",
                            name = "First-038 Surname-014",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-009",
                            name = "First-010 Surname-010",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-026",
                            name = "First-027 Surname-026",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-042",
                            name = "First-043 Surname-038",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-048",
                            name = "First-048 Surname-042",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-036",
                            name = "First-037 Surname-033",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-020",
                            name = "First-021 Surname-020",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-019",
                            name = "First-020 Surname-019",
                        },
                    },
                    sequence = 9,
                    trigger = "GUILD_ROSTER_UPDATE",
                },
                {
                    availability = {
                        guildRosterMemberCount = true,
                        guildRosterOnlineCount = true,
                        memberListCount = false,
                    },
                    errors = {
                        "GET_GUILD_CLUB_ID_UNAVAILABLE",
                    },
                    guild = {
                        availability = {
                            clubId = false,
                            memberCount = false,
                            name = true,
                            realm = false,
                        },
                        name = "Guild-001",
                    },
                    guildRosterMemberCount = 56,
                    guildRosterOnlineCount = 3,
                    memberSource = "guild-roster",
                    members = {
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-052",
                            name = "First-052 Surname-046",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-011",
                            name = "First-012 Surname-012",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-047",
                            name = "First-001 Surname-001",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-034",
                            name = "First-035 Surname-031",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-029",
                            name = "First-030 Surname-028",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-041",
                            name = "First-042 Surname-037",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-028",
                            name = "First-029 Surname-027",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-046",
                            name = "First-047 Surname-041",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-033",
                            name = "First-034 Surname-014",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-021",
                            name = "First-022 Surname-021",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-022",
                            name = "First-023 Surname-022",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-016",
                            name = "First-017 Surname-017",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-040",
                            name = "First-041 Surname-036",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-056",
                            name = "First-056 Surname-050",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-027",
                            name = "First-028 Surname-010",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-006",
                            name = "First-007 Surname-007",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-035",
                            name = "First-036 Surname-032",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-017",
                            name = "First-018 Surname-018",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-015",
                            name = "First-016 Surname-016",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-010",
                            name = "First-011 Surname-011",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-007",
                            name = "First-008 Surname-008",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-025",
                            name = "First-026 Surname-025",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-051",
                            name = "First-051 Surname-045",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-045",
                            name = "First-046 Surname-021",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-024",
                            name = "First-025 Surname-024",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-013",
                            name = "First-014 Surname-014",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-050",
                            name = "First-050 Surname-044",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-049",
                            name = "First-049 Surname-043",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-003",
                            name = "First-004 Surname-004",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-039",
                            name = "First-040 Surname-035",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-012",
                            name = "First-013 Surname-013",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-018",
                            name = "First-019 Surname-013",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-032",
                            name = "First-033 Surname-030",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-031",
                            name = "First-032 Surname-029",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-055",
                            name = "First-055 Surname-049",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-002",
                            name = "First-003 Surname-003",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-014",
                            name = "First-015 Surname-015",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-004",
                            name = "First-005 Surname-005",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-043",
                            name = "First-044 Surname-039",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-054",
                            name = "First-054 Surname-048",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-038",
                            name = "First-039 Surname-034",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-044",
                            name = "First-045 Surname-040",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-053",
                            name = "First-053 Surname-047",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-030",
                            name = "First-031 Surname-011",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-023",
                            name = "First-024 Surname-023",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-005",
                            name = "First-006 Surname-006",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-008",
                            name = "First-009 Surname-009",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-001",
                            name = "First-002 Surname-002",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-037",
                            name = "First-038 Surname-014",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-009",
                            name = "First-010 Surname-010",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-026",
                            name = "First-027 Surname-026",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-042",
                            name = "First-043 Surname-038",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-048",
                            name = "First-048 Surname-042",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-036",
                            name = "First-037 Surname-033",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-020",
                            name = "First-021 Surname-020",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-019",
                            name = "First-020 Surname-019",
                        },
                    },
                    sequence = 10,
                    trigger = "GUILD_ROSTER_UPDATE",
                },
                {
                    availability = {
                        guildRosterMemberCount = true,
                        guildRosterOnlineCount = true,
                        memberListCount = true,
                    },
                    errors = {
                    },
                    guild = {
                        availability = {
                            clubId = true,
                            memberCount = true,
                            name = true,
                            realm = false,
                        },
                        clubId = "Club-001",
                        memberCount = 56,
                        name = "Guild-001",
                    },
                    guildRosterMemberCount = 56,
                    guildRosterOnlineCount = 3,
                    memberListCount = 56,
                    memberSource = "club",
                    members = {
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-001",
                            name = "First-002 Surname-002",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-002",
                            name = "First-003 Surname-003",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-003",
                            name = "First-004 Surname-004",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-004",
                            name = "First-005 Surname-005",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-005",
                            name = "First-006 Surname-006",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-006",
                            name = "First-007 Surname-007",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-007",
                            name = "First-008 Surname-008",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-008",
                            name = "First-009 Surname-009",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-009",
                            name = "First-010 Surname-010",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-010",
                            name = "First-011 Surname-011",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-011",
                            name = "First-012 Surname-012",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-012",
                            name = "First-013 Surname-013",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-013",
                            name = "First-014 Surname-014",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-014",
                            name = "First-015 Surname-015",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-015",
                            name = "First-016 Surname-016",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-016",
                            name = "First-017 Surname-017",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-017",
                            name = "First-018 Surname-018",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-018",
                            name = "First-019 Surname-013",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-019",
                            name = "First-020 Surname-019",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-020",
                            name = "First-021 Surname-020",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-021",
                            name = "First-022 Surname-021",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-022",
                            name = "First-023 Surname-022",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-023",
                            name = "First-024 Surname-023",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-024",
                            name = "First-025 Surname-024",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-025",
                            name = "First-026 Surname-025",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-026",
                            name = "First-027 Surname-026",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-027",
                            name = "First-028 Surname-010",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-028",
                            name = "First-029 Surname-027",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-029",
                            name = "First-030 Surname-028",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-030",
                            name = "First-031 Surname-011",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-031",
                            name = "First-032 Surname-029",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-032",
                            name = "First-033 Surname-030",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-033",
                            name = "First-034 Surname-014",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-034",
                            name = "First-035 Surname-031",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-035",
                            name = "First-036 Surname-032",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-036",
                            name = "First-037 Surname-033",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-037",
                            name = "First-038 Surname-014",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-038",
                            name = "First-039 Surname-034",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-039",
                            name = "First-040 Surname-035",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-040",
                            name = "First-041 Surname-036",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-041",
                            name = "First-042 Surname-037",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-042",
                            name = "First-043 Surname-038",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-043",
                            name = "First-044 Surname-039",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-044",
                            name = "First-045 Surname-040",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-045",
                            name = "First-046 Surname-021",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-046",
                            name = "First-047 Surname-041",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-047",
                            name = "First-001 Surname-001",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-048",
                            name = "First-048 Surname-042",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-049",
                            name = "First-049 Surname-043",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-050",
                            name = "First-050 Surname-044",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-051",
                            name = "First-051 Surname-045",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-052",
                            name = "First-052 Surname-046",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-053",
                            name = "First-053 Surname-047",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-054",
                            name = "First-054 Surname-048",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-055",
                            name = "First-055 Surname-049",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-056",
                            name = "First-056 Surname-050",
                        },
                    },
                    sequence = 11,
                    trigger = "GUILD_ROSTER_UPDATE",
                },
                {
                    availability = {
                        guildRosterMemberCount = true,
                        guildRosterOnlineCount = true,
                        memberListCount = true,
                    },
                    errors = {
                    },
                    guild = {
                        availability = {
                            clubId = true,
                            memberCount = true,
                            name = true,
                            realm = false,
                        },
                        clubId = "Club-001",
                        memberCount = 56,
                        name = "Guild-001",
                    },
                    guildRosterMemberCount = 56,
                    guildRosterOnlineCount = 3,
                    memberListCount = 56,
                    memberSource = "club",
                    members = {
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-001",
                            name = "First-002 Surname-002",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-002",
                            name = "First-003 Surname-003",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-003",
                            name = "First-004 Surname-004",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-004",
                            name = "First-005 Surname-005",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-005",
                            name = "First-006 Surname-006",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-006",
                            name = "First-007 Surname-007",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-007",
                            name = "First-008 Surname-008",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-008",
                            name = "First-009 Surname-009",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-009",
                            name = "First-010 Surname-010",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-010",
                            name = "First-011 Surname-011",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-011",
                            name = "First-012 Surname-012",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-012",
                            name = "First-013 Surname-013",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-013",
                            name = "First-014 Surname-014",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-014",
                            name = "First-015 Surname-015",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-015",
                            name = "First-016 Surname-016",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-016",
                            name = "First-017 Surname-017",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-017",
                            name = "First-018 Surname-018",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-018",
                            name = "First-019 Surname-013",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-019",
                            name = "First-020 Surname-019",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-020",
                            name = "First-021 Surname-020",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-021",
                            name = "First-022 Surname-021",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-022",
                            name = "First-023 Surname-022",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-023",
                            name = "First-024 Surname-023",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-024",
                            name = "First-025 Surname-024",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-025",
                            name = "First-026 Surname-025",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-026",
                            name = "First-027 Surname-026",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-027",
                            name = "First-028 Surname-010",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-028",
                            name = "First-029 Surname-027",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-029",
                            name = "First-030 Surname-028",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-030",
                            name = "First-031 Surname-011",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-031",
                            name = "First-032 Surname-029",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-032",
                            name = "First-033 Surname-030",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-033",
                            name = "First-034 Surname-014",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-034",
                            name = "First-035 Surname-031",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-035",
                            name = "First-036 Surname-032",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-036",
                            name = "First-037 Surname-033",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-037",
                            name = "First-038 Surname-014",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-038",
                            name = "First-039 Surname-034",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-039",
                            name = "First-040 Surname-035",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-040",
                            name = "First-041 Surname-036",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-041",
                            name = "First-042 Surname-037",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-042",
                            name = "First-043 Surname-038",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-043",
                            name = "First-044 Surname-039",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-044",
                            name = "First-045 Surname-040",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-045",
                            name = "First-046 Surname-021",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-046",
                            name = "First-047 Surname-041",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-047",
                            name = "First-001 Surname-001",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-048",
                            name = "First-048 Surname-042",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-049",
                            name = "First-049 Surname-043",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-050",
                            name = "First-050 Surname-044",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-051",
                            name = "First-051 Surname-045",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-052",
                            name = "First-052 Surname-046",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-053",
                            name = "First-053 Surname-047",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-054",
                            name = "First-054 Surname-048",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-055",
                            name = "First-055 Surname-049",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-056",
                            name = "First-056 Surname-050",
                        },
                    },
                    sequence = 12,
                    trigger = "CLUB_MEMBERS_UPDATED",
                },
                {
                    availability = {
                        guildRosterMemberCount = true,
                        guildRosterOnlineCount = true,
                        memberListCount = true,
                    },
                    errors = {
                    },
                    guild = {
                        availability = {
                            clubId = true,
                            memberCount = true,
                            name = true,
                            realm = false,
                        },
                        clubId = "Club-001",
                        memberCount = 56,
                        name = "Guild-001",
                    },
                    guildRosterMemberCount = 56,
                    guildRosterOnlineCount = 3,
                    memberListCount = 56,
                    memberSource = "club",
                    members = {
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-001",
                            name = "First-002 Surname-002",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-002",
                            name = "First-003 Surname-003",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-003",
                            name = "First-004 Surname-004",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-004",
                            name = "First-005 Surname-005",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-005",
                            name = "First-006 Surname-006",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-006",
                            name = "First-007 Surname-007",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-007",
                            name = "First-008 Surname-008",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-008",
                            name = "First-009 Surname-009",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-009",
                            name = "First-010 Surname-010",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-010",
                            name = "First-011 Surname-011",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-011",
                            name = "First-012 Surname-012",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-012",
                            name = "First-013 Surname-013",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-013",
                            name = "First-014 Surname-014",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-014",
                            name = "First-015 Surname-015",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-015",
                            name = "First-016 Surname-016",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-016",
                            name = "First-017 Surname-017",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-017",
                            name = "First-018 Surname-018",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-018",
                            name = "First-019 Surname-013",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-019",
                            name = "First-020 Surname-019",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-020",
                            name = "First-021 Surname-020",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-021",
                            name = "First-022 Surname-021",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-022",
                            name = "First-023 Surname-022",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-023",
                            name = "First-024 Surname-023",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-024",
                            name = "First-025 Surname-024",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-025",
                            name = "First-026 Surname-025",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-026",
                            name = "First-027 Surname-026",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-027",
                            name = "First-028 Surname-010",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-028",
                            name = "First-029 Surname-027",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-029",
                            name = "First-030 Surname-028",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-030",
                            name = "First-031 Surname-011",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-031",
                            name = "First-032 Surname-029",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-032",
                            name = "First-033 Surname-030",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-033",
                            name = "First-034 Surname-014",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-034",
                            name = "First-035 Surname-031",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-035",
                            name = "First-036 Surname-032",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-036",
                            name = "First-037 Surname-033",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-037",
                            name = "First-038 Surname-014",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-038",
                            name = "First-039 Surname-034",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-039",
                            name = "First-040 Surname-035",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-040",
                            name = "First-041 Surname-036",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-041",
                            name = "First-042 Surname-037",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-042",
                            name = "First-043 Surname-038",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-043",
                            name = "First-044 Surname-039",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-044",
                            name = "First-045 Surname-040",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-045",
                            name = "First-046 Surname-021",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-046",
                            name = "First-047 Surname-041",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-047",
                            name = "First-001 Surname-001",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-048",
                            name = "First-048 Surname-042",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-049",
                            name = "First-049 Surname-043",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-050",
                            name = "First-050 Surname-044",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-051",
                            name = "First-051 Surname-045",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-052",
                            name = "First-052 Surname-046",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-053",
                            name = "First-053 Surname-047",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-054",
                            name = "First-054 Surname-048",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-055",
                            name = "First-055 Surname-049",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-056",
                            name = "First-056 Surname-050",
                        },
                    },
                    sequence = 13,
                    trigger = "INITIAL_CLUBS_LOADED",
                },
                {
                    availability = {
                        guildRosterMemberCount = true,
                        guildRosterOnlineCount = true,
                        memberListCount = true,
                    },
                    errors = {
                    },
                    guild = {
                        availability = {
                            clubId = true,
                            memberCount = true,
                            name = true,
                            realm = false,
                        },
                        clubId = "Club-001",
                        memberCount = 56,
                        name = "Guild-001",
                    },
                    guildRosterMemberCount = 56,
                    guildRosterOnlineCount = 3,
                    memberListCount = 56,
                    memberSource = "club",
                    members = {
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-001",
                            name = "First-002 Surname-002",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-002",
                            name = "First-003 Surname-003",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-003",
                            name = "First-004 Surname-004",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-004",
                            name = "First-005 Surname-005",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-005",
                            name = "First-006 Surname-006",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-006",
                            name = "First-007 Surname-007",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-007",
                            name = "First-008 Surname-008",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-008",
                            name = "First-009 Surname-009",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-009",
                            name = "First-010 Surname-010",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-010",
                            name = "First-011 Surname-011",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-011",
                            name = "First-012 Surname-012",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-012",
                            name = "First-013 Surname-013",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-013",
                            name = "First-014 Surname-014",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-014",
                            name = "First-015 Surname-015",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-015",
                            name = "First-016 Surname-016",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-016",
                            name = "First-017 Surname-017",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-017",
                            name = "First-018 Surname-018",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-018",
                            name = "First-019 Surname-013",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-019",
                            name = "First-020 Surname-019",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-020",
                            name = "First-021 Surname-020",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-021",
                            name = "First-022 Surname-021",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-022",
                            name = "First-023 Surname-022",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-023",
                            name = "First-024 Surname-023",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-024",
                            name = "First-025 Surname-024",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-025",
                            name = "First-026 Surname-025",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-026",
                            name = "First-027 Surname-026",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-027",
                            name = "First-028 Surname-010",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-028",
                            name = "First-029 Surname-027",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-029",
                            name = "First-030 Surname-028",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-030",
                            name = "First-031 Surname-011",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-031",
                            name = "First-032 Surname-029",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-032",
                            name = "First-033 Surname-030",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-033",
                            name = "First-034 Surname-014",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-034",
                            name = "First-035 Surname-031",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-035",
                            name = "First-036 Surname-032",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-036",
                            name = "First-037 Surname-033",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-037",
                            name = "First-038 Surname-014",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-038",
                            name = "First-039 Surname-034",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-039",
                            name = "First-040 Surname-035",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-040",
                            name = "First-041 Surname-036",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-041",
                            name = "First-042 Surname-037",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-042",
                            name = "First-043 Surname-038",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-043",
                            name = "First-044 Surname-039",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-044",
                            name = "First-045 Surname-040",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-045",
                            name = "First-046 Surname-021",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-046",
                            name = "First-047 Surname-041",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-047",
                            name = "First-001 Surname-001",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-048",
                            name = "First-048 Surname-042",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-049",
                            name = "First-049 Surname-043",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-050",
                            name = "First-050 Surname-044",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-051",
                            name = "First-051 Surname-045",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-052",
                            name = "First-052 Surname-046",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-053",
                            name = "First-053 Surname-047",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-054",
                            name = "First-054 Surname-048",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-055",
                            name = "First-055 Surname-049",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-056",
                            name = "First-056 Surname-050",
                        },
                    },
                    sequence = 14,
                    trigger = "MANUAL_SNAPSHOT",
                },
                {
                    availability = {
                        guildRosterMemberCount = true,
                        guildRosterOnlineCount = true,
                        memberListCount = true,
                    },
                    errors = {
                    },
                    guild = {
                        availability = {
                            clubId = true,
                            memberCount = true,
                            name = true,
                            realm = false,
                        },
                        clubId = "Club-001",
                        memberCount = 56,
                        name = "Guild-001",
                    },
                    guildRosterMemberCount = 56,
                    guildRosterOnlineCount = 3,
                    memberListCount = 56,
                    memberSource = "club",
                    members = {
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-001",
                            name = "First-002 Surname-002",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-002",
                            name = "First-003 Surname-003",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-003",
                            name = "First-004 Surname-004",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-004",
                            name = "First-005 Surname-005",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-005",
                            name = "First-006 Surname-006",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-006",
                            name = "First-007 Surname-007",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-007",
                            name = "First-008 Surname-008",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-008",
                            name = "First-009 Surname-009",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-009",
                            name = "First-010 Surname-010",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-010",
                            name = "First-011 Surname-011",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-011",
                            name = "First-012 Surname-012",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-012",
                            name = "First-013 Surname-013",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-013",
                            name = "First-014 Surname-014",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-014",
                            name = "First-015 Surname-015",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-015",
                            name = "First-016 Surname-016",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-016",
                            name = "First-017 Surname-017",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-017",
                            name = "First-018 Surname-018",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-018",
                            name = "First-019 Surname-013",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-019",
                            name = "First-020 Surname-019",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-020",
                            name = "First-021 Surname-020",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-021",
                            name = "First-022 Surname-021",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-022",
                            name = "First-023 Surname-022",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-023",
                            name = "First-024 Surname-023",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-024",
                            name = "First-025 Surname-024",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-025",
                            name = "First-026 Surname-025",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-026",
                            name = "First-027 Surname-026",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-027",
                            name = "First-028 Surname-010",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-028",
                            name = "First-029 Surname-027",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-029",
                            name = "First-030 Surname-028",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-030",
                            name = "First-031 Surname-011",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-031",
                            name = "First-032 Surname-029",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-032",
                            name = "First-033 Surname-030",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-033",
                            name = "First-034 Surname-014",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-034",
                            name = "First-035 Surname-031",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-035",
                            name = "First-036 Surname-032",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-036",
                            name = "First-037 Surname-033",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-037",
                            name = "First-038 Surname-014",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-038",
                            name = "First-039 Surname-034",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-039",
                            name = "First-040 Surname-035",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-040",
                            name = "First-041 Surname-036",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-041",
                            name = "First-042 Surname-037",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-042",
                            name = "First-043 Surname-038",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-043",
                            name = "First-044 Surname-039",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-044",
                            name = "First-045 Surname-040",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-045",
                            name = "First-046 Surname-021",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-046",
                            name = "First-047 Surname-041",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-047",
                            name = "First-001 Surname-001",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-048",
                            name = "First-048 Surname-042",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-049",
                            name = "First-049 Surname-043",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-050",
                            name = "First-050 Surname-044",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-051",
                            name = "First-051 Surname-045",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-052",
                            name = "First-052 Surname-046",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-053",
                            name = "First-053 Surname-047",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-054",
                            name = "First-054 Surname-048",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-055",
                            name = "First-055 Surname-049",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-056",
                            name = "First-056 Surname-050",
                        },
                    },
                    sequence = 15,
                    trigger = "GUILD_ROSTER_UPDATE",
                },
                {
                    availability = {
                        guildRosterMemberCount = true,
                        guildRosterOnlineCount = true,
                        memberListCount = true,
                    },
                    errors = {
                        "GET_GUILD_ROSTER_INFO_INCOMPLETE",
                    },
                    guild = {
                        availability = {
                            clubId = true,
                            memberCount = true,
                            name = true,
                            realm = false,
                        },
                        clubId = "Club-001",
                        memberCount = 56,
                        name = "Guild-001",
                    },
                    guildRosterMemberCount = 56,
                    guildRosterOnlineCount = 3,
                    memberListCount = 56,
                    memberSource = "club",
                    members = {
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-001",
                            name = "First-002 Surname-002",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-002",
                            name = "First-003 Surname-003",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-003",
                            name = "First-004 Surname-004",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-004",
                            name = "First-005 Surname-005",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-005",
                            name = "First-006 Surname-006",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-006",
                            name = "First-007 Surname-007",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-007",
                            name = "First-008 Surname-008",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-008",
                            name = "First-009 Surname-009",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-009",
                            name = "First-010 Surname-010",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-010",
                            name = "First-011 Surname-011",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-011",
                            name = "First-012 Surname-012",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-012",
                            name = "First-013 Surname-013",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-013",
                            name = "First-014 Surname-014",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-014",
                            name = "First-015 Surname-015",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-015",
                            name = "First-016 Surname-016",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-016",
                            name = "First-017 Surname-017",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-017",
                            name = "First-018 Surname-018",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-018",
                            name = "First-019 Surname-013",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-019",
                            name = "First-020 Surname-019",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-020",
                            name = "First-021 Surname-020",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-021",
                            name = "First-022 Surname-021",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-022",
                            name = "First-023 Surname-022",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-023",
                            name = "First-024 Surname-023",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-024",
                            name = "First-025 Surname-024",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-025",
                            name = "First-026 Surname-025",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-026",
                            name = "First-027 Surname-026",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-027",
                            name = "First-028 Surname-010",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-028",
                            name = "First-029 Surname-027",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-029",
                            name = "First-030 Surname-028",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-030",
                            name = "First-031 Surname-011",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-031",
                            name = "First-032 Surname-029",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-032",
                            name = "First-033 Surname-030",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-033",
                            name = "First-034 Surname-014",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-034",
                            name = "First-035 Surname-031",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-035",
                            name = "First-036 Surname-032",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-036",
                            name = "First-037 Surname-033",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-037",
                            name = "First-038 Surname-014",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-038",
                            name = "First-039 Surname-034",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-039",
                            name = "First-040 Surname-035",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-040",
                            name = "First-041 Surname-036",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-041",
                            name = "First-042 Surname-037",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-042",
                            name = "First-043 Surname-038",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-043",
                            name = "First-044 Surname-039",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-044",
                            name = "First-045 Surname-040",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-045",
                            name = "First-046 Surname-021",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-046",
                            name = "First-047 Surname-041",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-047",
                            name = "First-001 Surname-001",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-048",
                            name = "First-048 Surname-042",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-049",
                            name = "First-049 Surname-043",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-050",
                            name = "First-050 Surname-044",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-051",
                            name = "First-051 Surname-045",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-052",
                            name = "First-052 Surname-046",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-053",
                            name = "First-053 Surname-047",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-054",
                            name = "First-054 Surname-048",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-055",
                            name = "First-055 Surname-049",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-056",
                            name = "First-056 Surname-050",
                        },
                    },
                    sequence = 16,
                    trigger = "PLAYER_LEAVING_WORLD",
                },
                {
                    availability = {
                        guildRosterMemberCount = true,
                        guildRosterOnlineCount = true,
                        memberListCount = true,
                    },
                    errors = {
                        "GET_GUILD_ROSTER_INFO_INCOMPLETE",
                    },
                    guild = {
                        availability = {
                            clubId = true,
                            memberCount = true,
                            name = true,
                            realm = false,
                        },
                        clubId = "Club-001",
                        memberCount = 56,
                        name = "Guild-001",
                    },
                    guildRosterMemberCount = 56,
                    guildRosterOnlineCount = 3,
                    memberListCount = 56,
                    memberSource = "club",
                    members = {
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-001",
                            name = "First-002 Surname-002",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-002",
                            name = "First-003 Surname-003",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-003",
                            name = "First-004 Surname-004",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-004",
                            name = "First-005 Surname-005",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-005",
                            name = "First-006 Surname-006",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-006",
                            name = "First-007 Surname-007",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-007",
                            name = "First-008 Surname-008",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-008",
                            name = "First-009 Surname-009",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-009",
                            name = "First-010 Surname-010",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-010",
                            name = "First-011 Surname-011",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-011",
                            name = "First-012 Surname-012",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-012",
                            name = "First-013 Surname-013",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-013",
                            name = "First-014 Surname-014",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-014",
                            name = "First-015 Surname-015",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-015",
                            name = "First-016 Surname-016",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-016",
                            name = "First-017 Surname-017",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-017",
                            name = "First-018 Surname-018",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-018",
                            name = "First-019 Surname-013",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-019",
                            name = "First-020 Surname-019",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-020",
                            name = "First-021 Surname-020",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-021",
                            name = "First-022 Surname-021",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-022",
                            name = "First-023 Surname-022",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-023",
                            name = "First-024 Surname-023",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-024",
                            name = "First-025 Surname-024",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-025",
                            name = "First-026 Surname-025",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-026",
                            name = "First-027 Surname-026",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-027",
                            name = "First-028 Surname-010",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-028",
                            name = "First-029 Surname-027",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-029",
                            name = "First-030 Surname-028",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-030",
                            name = "First-031 Surname-011",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-031",
                            name = "First-032 Surname-029",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-032",
                            name = "First-033 Surname-030",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-033",
                            name = "First-034 Surname-014",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-034",
                            name = "First-035 Surname-031",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-035",
                            name = "First-036 Surname-032",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-036",
                            name = "First-037 Surname-033",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-037",
                            name = "First-038 Surname-014",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-038",
                            name = "First-039 Surname-034",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-039",
                            name = "First-040 Surname-035",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-040",
                            name = "First-041 Surname-036",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-041",
                            name = "First-042 Surname-037",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-042",
                            name = "First-043 Surname-038",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-043",
                            name = "First-044 Surname-039",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-044",
                            name = "First-045 Surname-040",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-045",
                            name = "First-046 Surname-021",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-046",
                            name = "First-047 Surname-041",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-047",
                            name = "First-001 Surname-001",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-048",
                            name = "First-048 Surname-042",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-049",
                            name = "First-049 Surname-043",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-050",
                            name = "First-050 Surname-044",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-051",
                            name = "First-051 Surname-045",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-052",
                            name = "First-052 Surname-046",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-053",
                            name = "First-053 Surname-047",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-054",
                            name = "First-054 Surname-048",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-055",
                            name = "First-055 Surname-049",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-056",
                            name = "First-056 Surname-050",
                        },
                    },
                    sequence = 17,
                    trigger = "PLAYER_LOGOUT",
                },
            },
            runtime = {
                availability = {
                    build = true,
                    interface = true,
                    normalizedRealmName = false,
                    playerName = true,
                    playerRealm = true,
                    productId = true,
                    realmName = true,
                    region = true,
                    version = true,
                },
                build = "70888",
                errors = {
                    "GET_NORMALIZED_REALM_NAME_UNAVAILABLE",
                },
                interface = 16001,
                playerName = "First-001 Surname-001",
                playerRealm = "Realm-003",
                productId = 18,
                realmName = "Realm-001",
                region = "US",
                version = "1.60.1",
            },
        },
        {
            boundary = "cold-restart",
            events = {
                {
                    availability = {
                        canRequestRosterUpdate = false,
                        clubId = false,
                        memberId = false,
                    },
                    name = "ADDON_LOADED",
                    sequence = 1,
                },
                {
                    availability = {
                        canRequestRosterUpdate = true,
                        clubId = false,
                        memberId = false,
                    },
                    canRequestRosterUpdate = false,
                    name = "GUILD_ROSTER_UPDATE",
                    sequence = 2,
                },
                {
                    availability = {
                        canRequestRosterUpdate = true,
                        clubId = false,
                        memberId = false,
                    },
                    canRequestRosterUpdate = true,
                    name = "GUILD_ROSTER_UPDATE",
                    sequence = 3,
                },
                {
                    availability = {
                        canRequestRosterUpdate = false,
                        clubId = false,
                        memberId = false,
                    },
                    name = "PLAYER_GUILD_UPDATE",
                    sequence = 4,
                },
                {
                    availability = {
                        canRequestRosterUpdate = false,
                        clubId = false,
                        memberId = false,
                    },
                    name = "PLAYER_LOGIN",
                    sequence = 5,
                },
                {
                    availability = {
                        canRequestRosterUpdate = false,
                        clubId = false,
                        memberId = false,
                    },
                    name = "PLAYER_ENTERING_WORLD",
                    sequence = 6,
                },
                {
                    availability = {
                        canRequestRosterUpdate = false,
                        clubId = false,
                        memberId = false,
                    },
                    name = "PLAYER_GUILD_UPDATE",
                    sequence = 7,
                },
                {
                    availability = {
                        canRequestRosterUpdate = true,
                        clubId = false,
                        memberId = false,
                    },
                    canRequestRosterUpdate = false,
                    name = "GUILD_ROSTER_UPDATE",
                    sequence = 8,
                },
                {
                    availability = {
                        canRequestRosterUpdate = true,
                        clubId = false,
                        memberId = false,
                    },
                    canRequestRosterUpdate = false,
                    name = "GUILD_ROSTER_UPDATE",
                    sequence = 9,
                },
                {
                    availability = {
                        canRequestRosterUpdate = true,
                        clubId = false,
                        memberId = false,
                    },
                    canRequestRosterUpdate = false,
                    name = "GUILD_ROSTER_UPDATE",
                    sequence = 10,
                },
                {
                    availability = {
                        canRequestRosterUpdate = false,
                        clubId = true,
                        memberId = false,
                    },
                    clubId = "Club-001",
                    name = "CLUB_MEMBERS_UPDATED",
                    sequence = 11,
                },
                {
                    availability = {
                        canRequestRosterUpdate = false,
                        clubId = false,
                        memberId = false,
                    },
                    name = "INITIAL_CLUBS_LOADED",
                    sequence = 12,
                },
                {
                    availability = {
                        canRequestRosterUpdate = false,
                        clubId = false,
                        memberId = false,
                    },
                    name = "MANUAL_SNAPSHOT",
                    sequence = 13,
                },
                {
                    availability = {
                        canRequestRosterUpdate = true,
                        clubId = false,
                        memberId = false,
                    },
                    canRequestRosterUpdate = false,
                    name = "GUILD_ROSTER_UPDATE",
                    sequence = 14,
                },
                {
                    availability = {
                        canRequestRosterUpdate = false,
                        clubId = false,
                        memberId = false,
                    },
                    name = "PLAYER_LEAVING_WORLD",
                    sequence = 15,
                },
                {
                    availability = {
                        canRequestRosterUpdate = false,
                        clubId = false,
                        memberId = false,
                    },
                    name = "PLAYER_LOGOUT",
                    sequence = 16,
                },
            },
            index = 4,
            observations = {
                {
                    availability = {
                        guildRosterMemberCount = true,
                        guildRosterOnlineCount = true,
                        memberListCount = false,
                    },
                    errors = {
                        "GET_GUILD_CLUB_ID_UNAVAILABLE",
                    },
                    guild = {
                        availability = {
                            clubId = false,
                            memberCount = false,
                            name = false,
                            realm = false,
                        },
                    },
                    guildRosterMemberCount = 0,
                    guildRosterOnlineCount = 0,
                    memberSource = "guild-roster",
                    members = {
                    },
                    sequence = 1,
                    trigger = "ADDON_LOADED",
                },
                {
                    availability = {
                        guildRosterMemberCount = true,
                        guildRosterOnlineCount = true,
                        memberListCount = false,
                    },
                    errors = {
                        "GET_GUILD_CLUB_ID_UNAVAILABLE",
                    },
                    guild = {
                        availability = {
                            clubId = false,
                            memberCount = false,
                            name = false,
                            realm = false,
                        },
                    },
                    guildRosterMemberCount = 0,
                    guildRosterOnlineCount = 0,
                    memberSource = "guild-roster",
                    members = {
                    },
                    sequence = 2,
                    trigger = "GUILD_ROSTER_UPDATE",
                },
                {
                    availability = {
                        guildRosterMemberCount = true,
                        guildRosterOnlineCount = true,
                        memberListCount = false,
                    },
                    errors = {
                        "GET_GUILD_CLUB_ID_UNAVAILABLE",
                    },
                    guild = {
                        availability = {
                            clubId = false,
                            memberCount = false,
                            name = false,
                            realm = false,
                        },
                    },
                    guildRosterMemberCount = 0,
                    guildRosterOnlineCount = 0,
                    memberSource = "guild-roster",
                    members = {
                    },
                    sequence = 3,
                    trigger = "GUILD_ROSTER_UPDATE",
                },
                {
                    availability = {
                        guildRosterMemberCount = true,
                        guildRosterOnlineCount = true,
                        memberListCount = false,
                    },
                    errors = {
                        "GET_GUILD_CLUB_ID_UNAVAILABLE",
                    },
                    guild = {
                        availability = {
                            clubId = false,
                            memberCount = false,
                            name = false,
                            realm = false,
                        },
                    },
                    guildRosterMemberCount = 0,
                    guildRosterOnlineCount = 0,
                    memberSource = "guild-roster",
                    members = {
                    },
                    sequence = 4,
                    trigger = "PLAYER_GUILD_UPDATE",
                },
                {
                    availability = {
                        guildRosterMemberCount = true,
                        guildRosterOnlineCount = true,
                        memberListCount = false,
                    },
                    errors = {
                        "GET_GUILD_CLUB_ID_UNAVAILABLE",
                    },
                    guild = {
                        availability = {
                            clubId = false,
                            memberCount = false,
                            name = false,
                            realm = false,
                        },
                    },
                    guildRosterMemberCount = 0,
                    guildRosterOnlineCount = 0,
                    memberSource = "guild-roster",
                    members = {
                    },
                    sequence = 5,
                    trigger = "PLAYER_LOGIN",
                },
                {
                    availability = {
                        guildRosterMemberCount = true,
                        guildRosterOnlineCount = true,
                        memberListCount = false,
                    },
                    errors = {
                        "GET_GUILD_CLUB_ID_UNAVAILABLE",
                    },
                    guild = {
                        availability = {
                            clubId = false,
                            memberCount = false,
                            name = false,
                            realm = false,
                        },
                    },
                    guildRosterMemberCount = 0,
                    guildRosterOnlineCount = 0,
                    memberSource = "guild-roster",
                    members = {
                    },
                    sequence = 6,
                    trigger = "PLAYER_ENTERING_WORLD",
                },
                {
                    availability = {
                        guildRosterMemberCount = true,
                        guildRosterOnlineCount = true,
                        memberListCount = false,
                    },
                    errors = {
                        "GET_GUILD_CLUB_ID_UNAVAILABLE",
                    },
                    guild = {
                        availability = {
                            clubId = false,
                            memberCount = false,
                            name = true,
                            realm = false,
                        },
                        name = "Guild-001",
                    },
                    guildRosterMemberCount = 0,
                    guildRosterOnlineCount = 0,
                    memberSource = "guild-roster",
                    members = {
                    },
                    sequence = 7,
                    trigger = "PLAYER_GUILD_UPDATE",
                },
                {
                    availability = {
                        guildRosterMemberCount = true,
                        guildRosterOnlineCount = true,
                        memberListCount = false,
                    },
                    errors = {
                        "GET_GUILD_CLUB_ID_UNAVAILABLE",
                    },
                    guild = {
                        availability = {
                            clubId = false,
                            memberCount = false,
                            name = true,
                            realm = false,
                        },
                        name = "Guild-001",
                    },
                    guildRosterMemberCount = 56,
                    guildRosterOnlineCount = 3,
                    memberSource = "guild-roster",
                    members = {
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-052",
                            name = "First-052 Surname-046",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-011",
                            name = "First-012 Surname-012",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-047",
                            name = "First-001 Surname-001",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-034",
                            name = "First-035 Surname-031",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-029",
                            name = "First-030 Surname-028",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-041",
                            name = "First-042 Surname-037",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-028",
                            name = "First-029 Surname-027",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-046",
                            name = "First-047 Surname-041",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-033",
                            name = "First-034 Surname-014",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-021",
                            name = "First-022 Surname-021",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-022",
                            name = "First-023 Surname-022",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-016",
                            name = "First-017 Surname-017",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-040",
                            name = "First-041 Surname-036",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-056",
                            name = "First-056 Surname-050",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-027",
                            name = "First-028 Surname-010",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-006",
                            name = "First-007 Surname-007",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-035",
                            name = "First-036 Surname-032",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-017",
                            name = "First-018 Surname-018",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-015",
                            name = "First-016 Surname-016",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-010",
                            name = "First-011 Surname-011",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-007",
                            name = "First-008 Surname-008",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-025",
                            name = "First-026 Surname-025",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-051",
                            name = "First-051 Surname-045",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-045",
                            name = "First-046 Surname-021",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-024",
                            name = "First-025 Surname-024",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-013",
                            name = "First-014 Surname-014",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-050",
                            name = "First-050 Surname-044",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-049",
                            name = "First-049 Surname-043",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-003",
                            name = "First-004 Surname-004",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-039",
                            name = "First-040 Surname-035",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-012",
                            name = "First-013 Surname-013",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-018",
                            name = "First-019 Surname-013",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-032",
                            name = "First-033 Surname-030",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-031",
                            name = "First-032 Surname-029",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-055",
                            name = "First-055 Surname-049",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-002",
                            name = "First-003 Surname-003",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-014",
                            name = "First-015 Surname-015",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-004",
                            name = "First-005 Surname-005",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-043",
                            name = "First-044 Surname-039",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-054",
                            name = "First-054 Surname-048",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-038",
                            name = "First-039 Surname-034",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-044",
                            name = "First-045 Surname-040",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-053",
                            name = "First-053 Surname-047",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-030",
                            name = "First-031 Surname-011",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-023",
                            name = "First-024 Surname-023",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-005",
                            name = "First-006 Surname-006",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-008",
                            name = "First-009 Surname-009",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-001",
                            name = "First-002 Surname-002",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-037",
                            name = "First-038 Surname-014",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-009",
                            name = "First-010 Surname-010",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-026",
                            name = "First-027 Surname-026",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-042",
                            name = "First-043 Surname-038",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-048",
                            name = "First-048 Surname-042",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-036",
                            name = "First-037 Surname-033",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-020",
                            name = "First-021 Surname-020",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-019",
                            name = "First-020 Surname-019",
                        },
                    },
                    sequence = 8,
                    trigger = "GUILD_ROSTER_UPDATE",
                },
                {
                    availability = {
                        guildRosterMemberCount = true,
                        guildRosterOnlineCount = true,
                        memberListCount = false,
                    },
                    errors = {
                        "GET_GUILD_CLUB_ID_UNAVAILABLE",
                    },
                    guild = {
                        availability = {
                            clubId = false,
                            memberCount = false,
                            name = true,
                            realm = false,
                        },
                        name = "Guild-001",
                    },
                    guildRosterMemberCount = 56,
                    guildRosterOnlineCount = 3,
                    memberSource = "guild-roster",
                    members = {
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-052",
                            name = "First-052 Surname-046",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-011",
                            name = "First-012 Surname-012",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-047",
                            name = "First-001 Surname-001",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-034",
                            name = "First-035 Surname-031",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-029",
                            name = "First-030 Surname-028",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-041",
                            name = "First-042 Surname-037",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-028",
                            name = "First-029 Surname-027",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-046",
                            name = "First-047 Surname-041",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-033",
                            name = "First-034 Surname-014",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-021",
                            name = "First-022 Surname-021",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-022",
                            name = "First-023 Surname-022",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-016",
                            name = "First-017 Surname-017",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-040",
                            name = "First-041 Surname-036",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-056",
                            name = "First-056 Surname-050",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-027",
                            name = "First-028 Surname-010",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-006",
                            name = "First-007 Surname-007",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-035",
                            name = "First-036 Surname-032",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-017",
                            name = "First-018 Surname-018",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-015",
                            name = "First-016 Surname-016",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-010",
                            name = "First-011 Surname-011",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-007",
                            name = "First-008 Surname-008",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-025",
                            name = "First-026 Surname-025",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-051",
                            name = "First-051 Surname-045",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-045",
                            name = "First-046 Surname-021",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-024",
                            name = "First-025 Surname-024",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-013",
                            name = "First-014 Surname-014",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-050",
                            name = "First-050 Surname-044",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-049",
                            name = "First-049 Surname-043",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-003",
                            name = "First-004 Surname-004",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-039",
                            name = "First-040 Surname-035",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-012",
                            name = "First-013 Surname-013",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-018",
                            name = "First-019 Surname-013",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-032",
                            name = "First-033 Surname-030",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-031",
                            name = "First-032 Surname-029",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-055",
                            name = "First-055 Surname-049",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-002",
                            name = "First-003 Surname-003",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-014",
                            name = "First-015 Surname-015",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-004",
                            name = "First-005 Surname-005",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-043",
                            name = "First-044 Surname-039",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-054",
                            name = "First-054 Surname-048",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-038",
                            name = "First-039 Surname-034",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-044",
                            name = "First-045 Surname-040",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-053",
                            name = "First-053 Surname-047",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-030",
                            name = "First-031 Surname-011",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-023",
                            name = "First-024 Surname-023",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-005",
                            name = "First-006 Surname-006",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-008",
                            name = "First-009 Surname-009",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-001",
                            name = "First-002 Surname-002",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-037",
                            name = "First-038 Surname-014",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-009",
                            name = "First-010 Surname-010",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-026",
                            name = "First-027 Surname-026",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-042",
                            name = "First-043 Surname-038",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-048",
                            name = "First-048 Surname-042",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-036",
                            name = "First-037 Surname-033",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-020",
                            name = "First-021 Surname-020",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-019",
                            name = "First-020 Surname-019",
                        },
                    },
                    sequence = 9,
                    trigger = "GUILD_ROSTER_UPDATE",
                },
                {
                    availability = {
                        guildRosterMemberCount = true,
                        guildRosterOnlineCount = true,
                        memberListCount = true,
                    },
                    errors = {
                    },
                    guild = {
                        availability = {
                            clubId = true,
                            memberCount = true,
                            name = true,
                            realm = false,
                        },
                        clubId = "Club-001",
                        memberCount = 56,
                        name = "Guild-001",
                    },
                    guildRosterMemberCount = 56,
                    guildRosterOnlineCount = 3,
                    memberListCount = 56,
                    memberSource = "club",
                    members = {
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-001",
                            name = "First-002 Surname-002",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-002",
                            name = "First-003 Surname-003",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-003",
                            name = "First-004 Surname-004",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-004",
                            name = "First-005 Surname-005",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-005",
                            name = "First-006 Surname-006",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-006",
                            name = "First-007 Surname-007",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-007",
                            name = "First-008 Surname-008",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-008",
                            name = "First-009 Surname-009",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-009",
                            name = "First-010 Surname-010",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-010",
                            name = "First-011 Surname-011",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-011",
                            name = "First-012 Surname-012",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-012",
                            name = "First-013 Surname-013",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-013",
                            name = "First-014 Surname-014",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-014",
                            name = "First-015 Surname-015",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-015",
                            name = "First-016 Surname-016",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-016",
                            name = "First-017 Surname-017",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-017",
                            name = "First-018 Surname-018",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-018",
                            name = "First-019 Surname-013",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-019",
                            name = "First-020 Surname-019",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-020",
                            name = "First-021 Surname-020",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-021",
                            name = "First-022 Surname-021",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-022",
                            name = "First-023 Surname-022",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-023",
                            name = "First-024 Surname-023",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-024",
                            name = "First-025 Surname-024",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-025",
                            name = "First-026 Surname-025",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-026",
                            name = "First-027 Surname-026",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-027",
                            name = "First-028 Surname-010",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-028",
                            name = "First-029 Surname-027",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-029",
                            name = "First-030 Surname-028",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-030",
                            name = "First-031 Surname-011",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-031",
                            name = "First-032 Surname-029",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-032",
                            name = "First-033 Surname-030",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-033",
                            name = "First-034 Surname-014",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-034",
                            name = "First-035 Surname-031",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-035",
                            name = "First-036 Surname-032",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-036",
                            name = "First-037 Surname-033",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-037",
                            name = "First-038 Surname-014",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-038",
                            name = "First-039 Surname-034",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-039",
                            name = "First-040 Surname-035",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-040",
                            name = "First-041 Surname-036",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-041",
                            name = "First-042 Surname-037",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-042",
                            name = "First-043 Surname-038",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-043",
                            name = "First-044 Surname-039",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-044",
                            name = "First-045 Surname-040",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-045",
                            name = "First-046 Surname-021",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-046",
                            name = "First-047 Surname-041",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-047",
                            name = "First-001 Surname-001",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-048",
                            name = "First-048 Surname-042",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-049",
                            name = "First-049 Surname-043",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-050",
                            name = "First-050 Surname-044",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-051",
                            name = "First-051 Surname-045",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-052",
                            name = "First-052 Surname-046",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-053",
                            name = "First-053 Surname-047",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-054",
                            name = "First-054 Surname-048",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-055",
                            name = "First-055 Surname-049",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-056",
                            name = "First-056 Surname-050",
                        },
                    },
                    sequence = 10,
                    trigger = "GUILD_ROSTER_UPDATE",
                },
                {
                    availability = {
                        guildRosterMemberCount = true,
                        guildRosterOnlineCount = true,
                        memberListCount = true,
                    },
                    errors = {
                    },
                    guild = {
                        availability = {
                            clubId = true,
                            memberCount = true,
                            name = true,
                            realm = false,
                        },
                        clubId = "Club-001",
                        memberCount = 56,
                        name = "Guild-001",
                    },
                    guildRosterMemberCount = 56,
                    guildRosterOnlineCount = 3,
                    memberListCount = 56,
                    memberSource = "club",
                    members = {
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-001",
                            name = "First-002 Surname-002",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-002",
                            name = "First-003 Surname-003",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-003",
                            name = "First-004 Surname-004",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-004",
                            name = "First-005 Surname-005",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-005",
                            name = "First-006 Surname-006",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-006",
                            name = "First-007 Surname-007",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-007",
                            name = "First-008 Surname-008",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-008",
                            name = "First-009 Surname-009",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-009",
                            name = "First-010 Surname-010",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-010",
                            name = "First-011 Surname-011",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-011",
                            name = "First-012 Surname-012",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-012",
                            name = "First-013 Surname-013",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-013",
                            name = "First-014 Surname-014",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-014",
                            name = "First-015 Surname-015",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-015",
                            name = "First-016 Surname-016",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-016",
                            name = "First-017 Surname-017",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-017",
                            name = "First-018 Surname-018",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-018",
                            name = "First-019 Surname-013",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-019",
                            name = "First-020 Surname-019",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-020",
                            name = "First-021 Surname-020",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-021",
                            name = "First-022 Surname-021",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-022",
                            name = "First-023 Surname-022",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-023",
                            name = "First-024 Surname-023",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-024",
                            name = "First-025 Surname-024",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-025",
                            name = "First-026 Surname-025",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-026",
                            name = "First-027 Surname-026",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-027",
                            name = "First-028 Surname-010",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-028",
                            name = "First-029 Surname-027",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-029",
                            name = "First-030 Surname-028",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-030",
                            name = "First-031 Surname-011",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-031",
                            name = "First-032 Surname-029",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-032",
                            name = "First-033 Surname-030",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-033",
                            name = "First-034 Surname-014",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-034",
                            name = "First-035 Surname-031",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-035",
                            name = "First-036 Surname-032",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-036",
                            name = "First-037 Surname-033",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-037",
                            name = "First-038 Surname-014",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-038",
                            name = "First-039 Surname-034",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-039",
                            name = "First-040 Surname-035",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-040",
                            name = "First-041 Surname-036",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-041",
                            name = "First-042 Surname-037",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-042",
                            name = "First-043 Surname-038",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-043",
                            name = "First-044 Surname-039",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-044",
                            name = "First-045 Surname-040",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-045",
                            name = "First-046 Surname-021",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-046",
                            name = "First-047 Surname-041",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-047",
                            name = "First-001 Surname-001",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-048",
                            name = "First-048 Surname-042",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-049",
                            name = "First-049 Surname-043",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-050",
                            name = "First-050 Surname-044",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-051",
                            name = "First-051 Surname-045",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-052",
                            name = "First-052 Surname-046",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-053",
                            name = "First-053 Surname-047",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-054",
                            name = "First-054 Surname-048",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-055",
                            name = "First-055 Surname-049",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-056",
                            name = "First-056 Surname-050",
                        },
                    },
                    sequence = 11,
                    trigger = "CLUB_MEMBERS_UPDATED",
                },
                {
                    availability = {
                        guildRosterMemberCount = true,
                        guildRosterOnlineCount = true,
                        memberListCount = true,
                    },
                    errors = {
                    },
                    guild = {
                        availability = {
                            clubId = true,
                            memberCount = true,
                            name = true,
                            realm = false,
                        },
                        clubId = "Club-001",
                        memberCount = 56,
                        name = "Guild-001",
                    },
                    guildRosterMemberCount = 56,
                    guildRosterOnlineCount = 3,
                    memberListCount = 56,
                    memberSource = "club",
                    members = {
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-001",
                            name = "First-002 Surname-002",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-002",
                            name = "First-003 Surname-003",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-003",
                            name = "First-004 Surname-004",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-004",
                            name = "First-005 Surname-005",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-005",
                            name = "First-006 Surname-006",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-006",
                            name = "First-007 Surname-007",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-007",
                            name = "First-008 Surname-008",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-008",
                            name = "First-009 Surname-009",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-009",
                            name = "First-010 Surname-010",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-010",
                            name = "First-011 Surname-011",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-011",
                            name = "First-012 Surname-012",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-012",
                            name = "First-013 Surname-013",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-013",
                            name = "First-014 Surname-014",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-014",
                            name = "First-015 Surname-015",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-015",
                            name = "First-016 Surname-016",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-016",
                            name = "First-017 Surname-017",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-017",
                            name = "First-018 Surname-018",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-018",
                            name = "First-019 Surname-013",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-019",
                            name = "First-020 Surname-019",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-020",
                            name = "First-021 Surname-020",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-021",
                            name = "First-022 Surname-021",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-022",
                            name = "First-023 Surname-022",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-023",
                            name = "First-024 Surname-023",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-024",
                            name = "First-025 Surname-024",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-025",
                            name = "First-026 Surname-025",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-026",
                            name = "First-027 Surname-026",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-027",
                            name = "First-028 Surname-010",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-028",
                            name = "First-029 Surname-027",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-029",
                            name = "First-030 Surname-028",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-030",
                            name = "First-031 Surname-011",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-031",
                            name = "First-032 Surname-029",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-032",
                            name = "First-033 Surname-030",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-033",
                            name = "First-034 Surname-014",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-034",
                            name = "First-035 Surname-031",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-035",
                            name = "First-036 Surname-032",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-036",
                            name = "First-037 Surname-033",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-037",
                            name = "First-038 Surname-014",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-038",
                            name = "First-039 Surname-034",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-039",
                            name = "First-040 Surname-035",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-040",
                            name = "First-041 Surname-036",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-041",
                            name = "First-042 Surname-037",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-042",
                            name = "First-043 Surname-038",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-043",
                            name = "First-044 Surname-039",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-044",
                            name = "First-045 Surname-040",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-045",
                            name = "First-046 Surname-021",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-046",
                            name = "First-047 Surname-041",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-047",
                            name = "First-001 Surname-001",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-048",
                            name = "First-048 Surname-042",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-049",
                            name = "First-049 Surname-043",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-050",
                            name = "First-050 Surname-044",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-051",
                            name = "First-051 Surname-045",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-052",
                            name = "First-052 Surname-046",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-053",
                            name = "First-053 Surname-047",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-054",
                            name = "First-054 Surname-048",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-055",
                            name = "First-055 Surname-049",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-056",
                            name = "First-056 Surname-050",
                        },
                    },
                    sequence = 12,
                    trigger = "INITIAL_CLUBS_LOADED",
                },
                {
                    availability = {
                        guildRosterMemberCount = true,
                        guildRosterOnlineCount = true,
                        memberListCount = true,
                    },
                    errors = {
                    },
                    guild = {
                        availability = {
                            clubId = true,
                            memberCount = true,
                            name = true,
                            realm = false,
                        },
                        clubId = "Club-001",
                        memberCount = 56,
                        name = "Guild-001",
                    },
                    guildRosterMemberCount = 56,
                    guildRosterOnlineCount = 3,
                    memberListCount = 56,
                    memberSource = "club",
                    members = {
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-001",
                            name = "First-002 Surname-002",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-002",
                            name = "First-003 Surname-003",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-003",
                            name = "First-004 Surname-004",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-004",
                            name = "First-005 Surname-005",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-005",
                            name = "First-006 Surname-006",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-006",
                            name = "First-007 Surname-007",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-007",
                            name = "First-008 Surname-008",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-008",
                            name = "First-009 Surname-009",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-009",
                            name = "First-010 Surname-010",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-010",
                            name = "First-011 Surname-011",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-011",
                            name = "First-012 Surname-012",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-012",
                            name = "First-013 Surname-013",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-013",
                            name = "First-014 Surname-014",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-014",
                            name = "First-015 Surname-015",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-015",
                            name = "First-016 Surname-016",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-016",
                            name = "First-017 Surname-017",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-017",
                            name = "First-018 Surname-018",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-018",
                            name = "First-019 Surname-013",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-019",
                            name = "First-020 Surname-019",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-020",
                            name = "First-021 Surname-020",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-021",
                            name = "First-022 Surname-021",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-022",
                            name = "First-023 Surname-022",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-023",
                            name = "First-024 Surname-023",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-024",
                            name = "First-025 Surname-024",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-025",
                            name = "First-026 Surname-025",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-026",
                            name = "First-027 Surname-026",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-027",
                            name = "First-028 Surname-010",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-028",
                            name = "First-029 Surname-027",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-029",
                            name = "First-030 Surname-028",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-030",
                            name = "First-031 Surname-011",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-031",
                            name = "First-032 Surname-029",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-032",
                            name = "First-033 Surname-030",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-033",
                            name = "First-034 Surname-014",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-034",
                            name = "First-035 Surname-031",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-035",
                            name = "First-036 Surname-032",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-036",
                            name = "First-037 Surname-033",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-037",
                            name = "First-038 Surname-014",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-038",
                            name = "First-039 Surname-034",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-039",
                            name = "First-040 Surname-035",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-040",
                            name = "First-041 Surname-036",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-041",
                            name = "First-042 Surname-037",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-042",
                            name = "First-043 Surname-038",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-043",
                            name = "First-044 Surname-039",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-044",
                            name = "First-045 Surname-040",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-045",
                            name = "First-046 Surname-021",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-046",
                            name = "First-047 Surname-041",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-047",
                            name = "First-001 Surname-001",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-048",
                            name = "First-048 Surname-042",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-049",
                            name = "First-049 Surname-043",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-050",
                            name = "First-050 Surname-044",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-051",
                            name = "First-051 Surname-045",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-052",
                            name = "First-052 Surname-046",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-053",
                            name = "First-053 Surname-047",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-054",
                            name = "First-054 Surname-048",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-055",
                            name = "First-055 Surname-049",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-056",
                            name = "First-056 Surname-050",
                        },
                    },
                    sequence = 13,
                    trigger = "MANUAL_SNAPSHOT",
                },
                {
                    availability = {
                        guildRosterMemberCount = true,
                        guildRosterOnlineCount = true,
                        memberListCount = true,
                    },
                    errors = {
                    },
                    guild = {
                        availability = {
                            clubId = true,
                            memberCount = true,
                            name = true,
                            realm = false,
                        },
                        clubId = "Club-001",
                        memberCount = 56,
                        name = "Guild-001",
                    },
                    guildRosterMemberCount = 56,
                    guildRosterOnlineCount = 3,
                    memberListCount = 56,
                    memberSource = "club",
                    members = {
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-001",
                            name = "First-002 Surname-002",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-002",
                            name = "First-003 Surname-003",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-003",
                            name = "First-004 Surname-004",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-004",
                            name = "First-005 Surname-005",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-005",
                            name = "First-006 Surname-006",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-006",
                            name = "First-007 Surname-007",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-007",
                            name = "First-008 Surname-008",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-008",
                            name = "First-009 Surname-009",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-009",
                            name = "First-010 Surname-010",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-010",
                            name = "First-011 Surname-011",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-011",
                            name = "First-012 Surname-012",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-012",
                            name = "First-013 Surname-013",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-013",
                            name = "First-014 Surname-014",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-014",
                            name = "First-015 Surname-015",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-015",
                            name = "First-016 Surname-016",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-016",
                            name = "First-017 Surname-017",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-017",
                            name = "First-018 Surname-018",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-018",
                            name = "First-019 Surname-013",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-019",
                            name = "First-020 Surname-019",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-020",
                            name = "First-021 Surname-020",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-021",
                            name = "First-022 Surname-021",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-022",
                            name = "First-023 Surname-022",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-023",
                            name = "First-024 Surname-023",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-024",
                            name = "First-025 Surname-024",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-025",
                            name = "First-026 Surname-025",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-026",
                            name = "First-027 Surname-026",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-027",
                            name = "First-028 Surname-010",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-028",
                            name = "First-029 Surname-027",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-029",
                            name = "First-030 Surname-028",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-030",
                            name = "First-031 Surname-011",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-031",
                            name = "First-032 Surname-029",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-032",
                            name = "First-033 Surname-030",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-033",
                            name = "First-034 Surname-014",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-034",
                            name = "First-035 Surname-031",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-035",
                            name = "First-036 Surname-032",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-036",
                            name = "First-037 Surname-033",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-037",
                            name = "First-038 Surname-014",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-038",
                            name = "First-039 Surname-034",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-039",
                            name = "First-040 Surname-035",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-040",
                            name = "First-041 Surname-036",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-041",
                            name = "First-042 Surname-037",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-042",
                            name = "First-043 Surname-038",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-043",
                            name = "First-044 Surname-039",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-044",
                            name = "First-045 Surname-040",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-045",
                            name = "First-046 Surname-021",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-046",
                            name = "First-047 Surname-041",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-047",
                            name = "First-001 Surname-001",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-048",
                            name = "First-048 Surname-042",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-049",
                            name = "First-049 Surname-043",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-050",
                            name = "First-050 Surname-044",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-051",
                            name = "First-051 Surname-045",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-052",
                            name = "First-052 Surname-046",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-053",
                            name = "First-053 Surname-047",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-054",
                            name = "First-054 Surname-048",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-055",
                            name = "First-055 Surname-049",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-056",
                            name = "First-056 Surname-050",
                        },
                    },
                    sequence = 14,
                    trigger = "GUILD_ROSTER_UPDATE",
                },
                {
                    availability = {
                        guildRosterMemberCount = true,
                        guildRosterOnlineCount = true,
                        memberListCount = false,
                    },
                    errors = {
                        "GET_GUILD_CLUB_ID_UNAVAILABLE",
                        "GET_GUILD_ROSTER_INFO_INCOMPLETE",
                    },
                    guild = {
                        availability = {
                            clubId = false,
                            memberCount = false,
                            name = false,
                            realm = false,
                        },
                    },
                    guildRosterMemberCount = 56,
                    guildRosterOnlineCount = 3,
                    memberSource = "guild-roster",
                    members = {
                        {
                            availability = {
                                guid = false,
                                name = false,
                            },
                        },
                        {
                            availability = {
                                guid = false,
                                name = false,
                            },
                        },
                        {
                            availability = {
                                guid = false,
                                name = false,
                            },
                        },
                        {
                            availability = {
                                guid = false,
                                name = false,
                            },
                        },
                        {
                            availability = {
                                guid = false,
                                name = false,
                            },
                        },
                        {
                            availability = {
                                guid = false,
                                name = false,
                            },
                        },
                        {
                            availability = {
                                guid = false,
                                name = false,
                            },
                        },
                        {
                            availability = {
                                guid = false,
                                name = false,
                            },
                        },
                        {
                            availability = {
                                guid = false,
                                name = false,
                            },
                        },
                        {
                            availability = {
                                guid = false,
                                name = false,
                            },
                        },
                        {
                            availability = {
                                guid = false,
                                name = false,
                            },
                        },
                        {
                            availability = {
                                guid = false,
                                name = false,
                            },
                        },
                        {
                            availability = {
                                guid = false,
                                name = false,
                            },
                        },
                        {
                            availability = {
                                guid = false,
                                name = false,
                            },
                        },
                        {
                            availability = {
                                guid = false,
                                name = false,
                            },
                        },
                        {
                            availability = {
                                guid = false,
                                name = false,
                            },
                        },
                        {
                            availability = {
                                guid = false,
                                name = false,
                            },
                        },
                        {
                            availability = {
                                guid = false,
                                name = false,
                            },
                        },
                        {
                            availability = {
                                guid = false,
                                name = false,
                            },
                        },
                        {
                            availability = {
                                guid = false,
                                name = false,
                            },
                        },
                        {
                            availability = {
                                guid = false,
                                name = false,
                            },
                        },
                        {
                            availability = {
                                guid = false,
                                name = false,
                            },
                        },
                        {
                            availability = {
                                guid = false,
                                name = false,
                            },
                        },
                        {
                            availability = {
                                guid = false,
                                name = false,
                            },
                        },
                        {
                            availability = {
                                guid = false,
                                name = false,
                            },
                        },
                        {
                            availability = {
                                guid = false,
                                name = false,
                            },
                        },
                        {
                            availability = {
                                guid = false,
                                name = false,
                            },
                        },
                        {
                            availability = {
                                guid = false,
                                name = false,
                            },
                        },
                        {
                            availability = {
                                guid = false,
                                name = false,
                            },
                        },
                        {
                            availability = {
                                guid = false,
                                name = false,
                            },
                        },
                        {
                            availability = {
                                guid = false,
                                name = false,
                            },
                        },
                        {
                            availability = {
                                guid = false,
                                name = false,
                            },
                        },
                        {
                            availability = {
                                guid = false,
                                name = false,
                            },
                        },
                        {
                            availability = {
                                guid = false,
                                name = false,
                            },
                        },
                        {
                            availability = {
                                guid = false,
                                name = false,
                            },
                        },
                        {
                            availability = {
                                guid = false,
                                name = false,
                            },
                        },
                        {
                            availability = {
                                guid = false,
                                name = false,
                            },
                        },
                        {
                            availability = {
                                guid = false,
                                name = false,
                            },
                        },
                        {
                            availability = {
                                guid = false,
                                name = false,
                            },
                        },
                        {
                            availability = {
                                guid = false,
                                name = false,
                            },
                        },
                        {
                            availability = {
                                guid = false,
                                name = false,
                            },
                        },
                        {
                            availability = {
                                guid = false,
                                name = false,
                            },
                        },
                        {
                            availability = {
                                guid = false,
                                name = false,
                            },
                        },
                        {
                            availability = {
                                guid = false,
                                name = false,
                            },
                        },
                        {
                            availability = {
                                guid = false,
                                name = false,
                            },
                        },
                        {
                            availability = {
                                guid = false,
                                name = false,
                            },
                        },
                        {
                            availability = {
                                guid = false,
                                name = false,
                            },
                        },
                        {
                            availability = {
                                guid = false,
                                name = false,
                            },
                        },
                        {
                            availability = {
                                guid = false,
                                name = false,
                            },
                        },
                        {
                            availability = {
                                guid = false,
                                name = false,
                            },
                        },
                        {
                            availability = {
                                guid = false,
                                name = false,
                            },
                        },
                        {
                            availability = {
                                guid = false,
                                name = false,
                            },
                        },
                        {
                            availability = {
                                guid = false,
                                name = false,
                            },
                        },
                        {
                            availability = {
                                guid = false,
                                name = false,
                            },
                        },
                        {
                            availability = {
                                guid = false,
                                name = false,
                            },
                        },
                        {
                            availability = {
                                guid = false,
                                name = false,
                            },
                        },
                    },
                    sequence = 15,
                    trigger = "PLAYER_LEAVING_WORLD",
                },
                {
                    availability = {
                        guildRosterMemberCount = true,
                        guildRosterOnlineCount = true,
                        memberListCount = false,
                    },
                    errors = {
                        "GET_GUILD_CLUB_ID_UNAVAILABLE",
                        "GET_GUILD_ROSTER_INFO_INCOMPLETE",
                    },
                    guild = {
                        availability = {
                            clubId = false,
                            memberCount = false,
                            name = false,
                            realm = false,
                        },
                    },
                    guildRosterMemberCount = 56,
                    guildRosterOnlineCount = 3,
                    memberSource = "guild-roster",
                    members = {
                        {
                            availability = {
                                guid = false,
                                name = false,
                            },
                        },
                        {
                            availability = {
                                guid = false,
                                name = false,
                            },
                        },
                        {
                            availability = {
                                guid = false,
                                name = false,
                            },
                        },
                        {
                            availability = {
                                guid = false,
                                name = false,
                            },
                        },
                        {
                            availability = {
                                guid = false,
                                name = false,
                            },
                        },
                        {
                            availability = {
                                guid = false,
                                name = false,
                            },
                        },
                        {
                            availability = {
                                guid = false,
                                name = false,
                            },
                        },
                        {
                            availability = {
                                guid = false,
                                name = false,
                            },
                        },
                        {
                            availability = {
                                guid = false,
                                name = false,
                            },
                        },
                        {
                            availability = {
                                guid = false,
                                name = false,
                            },
                        },
                        {
                            availability = {
                                guid = false,
                                name = false,
                            },
                        },
                        {
                            availability = {
                                guid = false,
                                name = false,
                            },
                        },
                        {
                            availability = {
                                guid = false,
                                name = false,
                            },
                        },
                        {
                            availability = {
                                guid = false,
                                name = false,
                            },
                        },
                        {
                            availability = {
                                guid = false,
                                name = false,
                            },
                        },
                        {
                            availability = {
                                guid = false,
                                name = false,
                            },
                        },
                        {
                            availability = {
                                guid = false,
                                name = false,
                            },
                        },
                        {
                            availability = {
                                guid = false,
                                name = false,
                            },
                        },
                        {
                            availability = {
                                guid = false,
                                name = false,
                            },
                        },
                        {
                            availability = {
                                guid = false,
                                name = false,
                            },
                        },
                        {
                            availability = {
                                guid = false,
                                name = false,
                            },
                        },
                        {
                            availability = {
                                guid = false,
                                name = false,
                            },
                        },
                        {
                            availability = {
                                guid = false,
                                name = false,
                            },
                        },
                        {
                            availability = {
                                guid = false,
                                name = false,
                            },
                        },
                        {
                            availability = {
                                guid = false,
                                name = false,
                            },
                        },
                        {
                            availability = {
                                guid = false,
                                name = false,
                            },
                        },
                        {
                            availability = {
                                guid = false,
                                name = false,
                            },
                        },
                        {
                            availability = {
                                guid = false,
                                name = false,
                            },
                        },
                        {
                            availability = {
                                guid = false,
                                name = false,
                            },
                        },
                        {
                            availability = {
                                guid = false,
                                name = false,
                            },
                        },
                        {
                            availability = {
                                guid = false,
                                name = false,
                            },
                        },
                        {
                            availability = {
                                guid = false,
                                name = false,
                            },
                        },
                        {
                            availability = {
                                guid = false,
                                name = false,
                            },
                        },
                        {
                            availability = {
                                guid = false,
                                name = false,
                            },
                        },
                        {
                            availability = {
                                guid = false,
                                name = false,
                            },
                        },
                        {
                            availability = {
                                guid = false,
                                name = false,
                            },
                        },
                        {
                            availability = {
                                guid = false,
                                name = false,
                            },
                        },
                        {
                            availability = {
                                guid = false,
                                name = false,
                            },
                        },
                        {
                            availability = {
                                guid = false,
                                name = false,
                            },
                        },
                        {
                            availability = {
                                guid = false,
                                name = false,
                            },
                        },
                        {
                            availability = {
                                guid = false,
                                name = false,
                            },
                        },
                        {
                            availability = {
                                guid = false,
                                name = false,
                            },
                        },
                        {
                            availability = {
                                guid = false,
                                name = false,
                            },
                        },
                        {
                            availability = {
                                guid = false,
                                name = false,
                            },
                        },
                        {
                            availability = {
                                guid = false,
                                name = false,
                            },
                        },
                        {
                            availability = {
                                guid = false,
                                name = false,
                            },
                        },
                        {
                            availability = {
                                guid = false,
                                name = false,
                            },
                        },
                        {
                            availability = {
                                guid = false,
                                name = false,
                            },
                        },
                        {
                            availability = {
                                guid = false,
                                name = false,
                            },
                        },
                        {
                            availability = {
                                guid = false,
                                name = false,
                            },
                        },
                        {
                            availability = {
                                guid = false,
                                name = false,
                            },
                        },
                        {
                            availability = {
                                guid = false,
                                name = false,
                            },
                        },
                        {
                            availability = {
                                guid = false,
                                name = false,
                            },
                        },
                        {
                            availability = {
                                guid = false,
                                name = false,
                            },
                        },
                        {
                            availability = {
                                guid = false,
                                name = false,
                            },
                        },
                        {
                            availability = {
                                guid = false,
                                name = false,
                            },
                        },
                    },
                    sequence = 16,
                    trigger = "PLAYER_LOGOUT",
                },
            },
            runtime = {
                availability = {
                    build = true,
                    interface = true,
                    normalizedRealmName = false,
                    playerName = true,
                    playerRealm = true,
                    productId = true,
                    realmName = true,
                    region = true,
                    version = true,
                },
                build = "70888",
                errors = {
                    "GET_NORMALIZED_REALM_NAME_UNAVAILABLE",
                },
                interface = 16001,
                playerName = "First-001 Surname-001",
                playerRealm = "Realm-003",
                productId = 18,
                realmName = "Realm-001",
                region = "US",
                version = "1.60.1",
            },
        },
        {
            boundary = "initial",
            events = {
                {
                    availability = {
                        canRequestRosterUpdate = false,
                        clubId = false,
                        memberId = false,
                    },
                    name = "ADDON_LOADED",
                    sequence = 1,
                },
                {
                    availability = {
                        canRequestRosterUpdate = true,
                        clubId = false,
                        memberId = false,
                    },
                    canRequestRosterUpdate = false,
                    name = "GUILD_ROSTER_UPDATE",
                    sequence = 2,
                },
                {
                    availability = {
                        canRequestRosterUpdate = false,
                        clubId = false,
                        memberId = false,
                    },
                    name = "PLAYER_GUILD_UPDATE",
                    sequence = 3,
                },
                {
                    availability = {
                        canRequestRosterUpdate = false,
                        clubId = false,
                        memberId = false,
                    },
                    name = "PLAYER_LOGIN",
                    sequence = 4,
                },
                {
                    availability = {
                        canRequestRosterUpdate = false,
                        clubId = false,
                        memberId = false,
                    },
                    name = "PLAYER_ENTERING_WORLD",
                    sequence = 5,
                },
                {
                    availability = {
                        canRequestRosterUpdate = true,
                        clubId = false,
                        memberId = false,
                    },
                    canRequestRosterUpdate = false,
                    name = "GUILD_ROSTER_UPDATE",
                    sequence = 6,
                },
                {
                    availability = {
                        canRequestRosterUpdate = false,
                        clubId = false,
                        memberId = false,
                    },
                    name = "PLAYER_GUILD_UPDATE",
                    sequence = 7,
                },
                {
                    availability = {
                        canRequestRosterUpdate = true,
                        clubId = false,
                        memberId = false,
                    },
                    canRequestRosterUpdate = false,
                    name = "GUILD_ROSTER_UPDATE",
                    sequence = 8,
                },
                {
                    availability = {
                        canRequestRosterUpdate = false,
                        clubId = true,
                        memberId = false,
                    },
                    clubId = "Club-001",
                    name = "CLUB_MEMBERS_UPDATED",
                    sequence = 9,
                },
                {
                    availability = {
                        canRequestRosterUpdate = false,
                        clubId = false,
                        memberId = false,
                    },
                    name = "INITIAL_CLUBS_LOADED",
                    sequence = 10,
                },
                {
                    availability = {
                        canRequestRosterUpdate = false,
                        clubId = false,
                        memberId = false,
                    },
                    name = "MANUAL_SNAPSHOT",
                    sequence = 11,
                },
                {
                    availability = {
                        canRequestRosterUpdate = true,
                        clubId = false,
                        memberId = false,
                    },
                    canRequestRosterUpdate = false,
                    name = "GUILD_ROSTER_UPDATE",
                    sequence = 12,
                },
                {
                    availability = {
                        canRequestRosterUpdate = false,
                        clubId = false,
                        memberId = false,
                    },
                    name = "PROBE_STOP",
                    sequence = 13,
                },
            },
            index = 5,
            observations = {
                {
                    availability = {
                        guildRosterMemberCount = true,
                        guildRosterOnlineCount = true,
                        memberListCount = false,
                    },
                    errors = {
                        "GET_GUILD_CLUB_ID_UNAVAILABLE",
                    },
                    guild = {
                        availability = {
                            clubId = false,
                            memberCount = false,
                            name = false,
                            realm = false,
                        },
                    },
                    guildRosterMemberCount = 0,
                    guildRosterOnlineCount = 0,
                    memberSource = "guild-roster",
                    members = {
                    },
                    sequence = 1,
                    trigger = "ADDON_LOADED",
                },
                {
                    availability = {
                        guildRosterMemberCount = true,
                        guildRosterOnlineCount = true,
                        memberListCount = false,
                    },
                    errors = {
                        "GET_GUILD_CLUB_ID_UNAVAILABLE",
                    },
                    guild = {
                        availability = {
                            clubId = false,
                            memberCount = false,
                            name = false,
                            realm = false,
                        },
                    },
                    guildRosterMemberCount = 0,
                    guildRosterOnlineCount = 0,
                    memberSource = "guild-roster",
                    members = {
                    },
                    sequence = 2,
                    trigger = "GUILD_ROSTER_UPDATE",
                },
                {
                    availability = {
                        guildRosterMemberCount = true,
                        guildRosterOnlineCount = true,
                        memberListCount = false,
                    },
                    errors = {
                        "GET_GUILD_CLUB_ID_UNAVAILABLE",
                    },
                    guild = {
                        availability = {
                            clubId = false,
                            memberCount = false,
                            name = false,
                            realm = false,
                        },
                    },
                    guildRosterMemberCount = 0,
                    guildRosterOnlineCount = 0,
                    memberSource = "guild-roster",
                    members = {
                    },
                    sequence = 3,
                    trigger = "PLAYER_GUILD_UPDATE",
                },
                {
                    availability = {
                        guildRosterMemberCount = true,
                        guildRosterOnlineCount = true,
                        memberListCount = false,
                    },
                    errors = {
                        "GET_GUILD_CLUB_ID_UNAVAILABLE",
                    },
                    guild = {
                        availability = {
                            clubId = false,
                            memberCount = false,
                            name = false,
                            realm = false,
                        },
                    },
                    guildRosterMemberCount = 0,
                    guildRosterOnlineCount = 0,
                    memberSource = "guild-roster",
                    members = {
                    },
                    sequence = 4,
                    trigger = "PLAYER_LOGIN",
                },
                {
                    availability = {
                        guildRosterMemberCount = true,
                        guildRosterOnlineCount = true,
                        memberListCount = false,
                    },
                    errors = {
                        "GET_GUILD_CLUB_ID_UNAVAILABLE",
                    },
                    guild = {
                        availability = {
                            clubId = false,
                            memberCount = false,
                            name = false,
                            realm = false,
                        },
                    },
                    guildRosterMemberCount = 0,
                    guildRosterOnlineCount = 0,
                    memberSource = "guild-roster",
                    members = {
                    },
                    sequence = 5,
                    trigger = "PLAYER_ENTERING_WORLD",
                },
                {
                    availability = {
                        guildRosterMemberCount = true,
                        guildRosterOnlineCount = true,
                        memberListCount = false,
                    },
                    errors = {
                        "GET_GUILD_CLUB_ID_UNAVAILABLE",
                    },
                    guild = {
                        availability = {
                            clubId = false,
                            memberCount = false,
                            name = false,
                            realm = false,
                        },
                    },
                    guildRosterMemberCount = 56,
                    guildRosterOnlineCount = 3,
                    memberSource = "guild-roster",
                    members = {
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-052",
                            name = "First-052 Surname-046",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-011",
                            name = "First-012 Surname-012",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-047",
                            name = "First-001 Surname-001",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-034",
                            name = "First-035 Surname-031",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-029",
                            name = "First-030 Surname-028",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-041",
                            name = "First-042 Surname-037",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-028",
                            name = "First-029 Surname-027",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-046",
                            name = "First-047 Surname-041",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-033",
                            name = "First-034 Surname-014",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-021",
                            name = "First-022 Surname-021",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-022",
                            name = "First-023 Surname-022",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-016",
                            name = "First-017 Surname-017",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-040",
                            name = "First-041 Surname-036",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-056",
                            name = "First-056 Surname-050",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-027",
                            name = "First-028 Surname-010",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-006",
                            name = "First-007 Surname-007",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-035",
                            name = "First-036 Surname-032",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-017",
                            name = "First-018 Surname-018",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-015",
                            name = "First-016 Surname-016",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-010",
                            name = "First-011 Surname-011",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-007",
                            name = "First-008 Surname-008",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-025",
                            name = "First-026 Surname-025",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-051",
                            name = "First-051 Surname-045",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-045",
                            name = "First-046 Surname-021",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-024",
                            name = "First-025 Surname-024",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-013",
                            name = "First-014 Surname-014",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-050",
                            name = "First-050 Surname-044",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-049",
                            name = "First-049 Surname-043",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-003",
                            name = "First-004 Surname-004",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-039",
                            name = "First-040 Surname-035",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-012",
                            name = "First-013 Surname-013",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-018",
                            name = "First-019 Surname-013",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-032",
                            name = "First-033 Surname-030",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-031",
                            name = "First-032 Surname-029",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-055",
                            name = "First-055 Surname-049",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-002",
                            name = "First-003 Surname-003",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-014",
                            name = "First-015 Surname-015",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-004",
                            name = "First-005 Surname-005",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-043",
                            name = "First-044 Surname-039",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-054",
                            name = "First-054 Surname-048",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-038",
                            name = "First-039 Surname-034",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-044",
                            name = "First-045 Surname-040",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-053",
                            name = "First-053 Surname-047",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-030",
                            name = "First-031 Surname-011",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-023",
                            name = "First-024 Surname-023",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-005",
                            name = "First-006 Surname-006",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-008",
                            name = "First-009 Surname-009",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-001",
                            name = "First-002 Surname-002",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-037",
                            name = "First-038 Surname-014",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-009",
                            name = "First-010 Surname-010",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-026",
                            name = "First-027 Surname-026",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-042",
                            name = "First-043 Surname-038",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-048",
                            name = "First-048 Surname-042",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-036",
                            name = "First-037 Surname-033",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-020",
                            name = "First-021 Surname-020",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-019",
                            name = "First-020 Surname-019",
                        },
                    },
                    sequence = 6,
                    trigger = "GUILD_ROSTER_UPDATE",
                },
                {
                    availability = {
                        guildRosterMemberCount = true,
                        guildRosterOnlineCount = true,
                        memberListCount = false,
                    },
                    errors = {
                        "GET_GUILD_CLUB_ID_UNAVAILABLE",
                    },
                    guild = {
                        availability = {
                            clubId = false,
                            memberCount = false,
                            name = true,
                            realm = false,
                        },
                        name = "Guild-001",
                    },
                    guildRosterMemberCount = 56,
                    guildRosterOnlineCount = 3,
                    memberSource = "guild-roster",
                    members = {
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-052",
                            name = "First-052 Surname-046",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-011",
                            name = "First-012 Surname-012",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-047",
                            name = "First-001 Surname-001",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-034",
                            name = "First-035 Surname-031",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-029",
                            name = "First-030 Surname-028",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-041",
                            name = "First-042 Surname-037",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-028",
                            name = "First-029 Surname-027",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-046",
                            name = "First-047 Surname-041",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-033",
                            name = "First-034 Surname-014",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-021",
                            name = "First-022 Surname-021",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-022",
                            name = "First-023 Surname-022",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-016",
                            name = "First-017 Surname-017",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-040",
                            name = "First-041 Surname-036",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-056",
                            name = "First-056 Surname-050",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-027",
                            name = "First-028 Surname-010",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-006",
                            name = "First-007 Surname-007",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-035",
                            name = "First-036 Surname-032",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-017",
                            name = "First-018 Surname-018",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-015",
                            name = "First-016 Surname-016",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-010",
                            name = "First-011 Surname-011",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-007",
                            name = "First-008 Surname-008",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-025",
                            name = "First-026 Surname-025",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-051",
                            name = "First-051 Surname-045",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-045",
                            name = "First-046 Surname-021",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-024",
                            name = "First-025 Surname-024",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-013",
                            name = "First-014 Surname-014",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-050",
                            name = "First-050 Surname-044",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-049",
                            name = "First-049 Surname-043",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-003",
                            name = "First-004 Surname-004",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-039",
                            name = "First-040 Surname-035",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-012",
                            name = "First-013 Surname-013",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-018",
                            name = "First-019 Surname-013",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-032",
                            name = "First-033 Surname-030",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-031",
                            name = "First-032 Surname-029",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-055",
                            name = "First-055 Surname-049",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-002",
                            name = "First-003 Surname-003",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-014",
                            name = "First-015 Surname-015",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-004",
                            name = "First-005 Surname-005",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-043",
                            name = "First-044 Surname-039",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-054",
                            name = "First-054 Surname-048",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-038",
                            name = "First-039 Surname-034",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-044",
                            name = "First-045 Surname-040",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-053",
                            name = "First-053 Surname-047",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-030",
                            name = "First-031 Surname-011",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-023",
                            name = "First-024 Surname-023",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-005",
                            name = "First-006 Surname-006",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-008",
                            name = "First-009 Surname-009",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-001",
                            name = "First-002 Surname-002",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-037",
                            name = "First-038 Surname-014",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-009",
                            name = "First-010 Surname-010",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-026",
                            name = "First-027 Surname-026",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-042",
                            name = "First-043 Surname-038",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-048",
                            name = "First-048 Surname-042",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-036",
                            name = "First-037 Surname-033",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-020",
                            name = "First-021 Surname-020",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-019",
                            name = "First-020 Surname-019",
                        },
                    },
                    sequence = 7,
                    trigger = "PLAYER_GUILD_UPDATE",
                },
                {
                    availability = {
                        guildRosterMemberCount = true,
                        guildRosterOnlineCount = true,
                        memberListCount = false,
                    },
                    errors = {
                        "GET_GUILD_CLUB_ID_UNAVAILABLE",
                    },
                    guild = {
                        availability = {
                            clubId = false,
                            memberCount = false,
                            name = true,
                            realm = false,
                        },
                        name = "Guild-001",
                    },
                    guildRosterMemberCount = 56,
                    guildRosterOnlineCount = 3,
                    memberSource = "guild-roster",
                    members = {
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-052",
                            name = "First-052 Surname-046",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-011",
                            name = "First-012 Surname-012",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-047",
                            name = "First-001 Surname-001",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-034",
                            name = "First-035 Surname-031",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-029",
                            name = "First-030 Surname-028",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-041",
                            name = "First-042 Surname-037",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-028",
                            name = "First-029 Surname-027",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-046",
                            name = "First-047 Surname-041",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-033",
                            name = "First-034 Surname-014",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-021",
                            name = "First-022 Surname-021",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-022",
                            name = "First-023 Surname-022",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-016",
                            name = "First-017 Surname-017",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-040",
                            name = "First-041 Surname-036",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-056",
                            name = "First-056 Surname-050",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-027",
                            name = "First-028 Surname-010",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-006",
                            name = "First-007 Surname-007",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-035",
                            name = "First-036 Surname-032",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-017",
                            name = "First-018 Surname-018",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-015",
                            name = "First-016 Surname-016",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-010",
                            name = "First-011 Surname-011",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-007",
                            name = "First-008 Surname-008",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-025",
                            name = "First-026 Surname-025",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-051",
                            name = "First-051 Surname-045",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-045",
                            name = "First-046 Surname-021",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-024",
                            name = "First-025 Surname-024",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-013",
                            name = "First-014 Surname-014",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-050",
                            name = "First-050 Surname-044",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-049",
                            name = "First-049 Surname-043",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-003",
                            name = "First-004 Surname-004",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-039",
                            name = "First-040 Surname-035",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-012",
                            name = "First-013 Surname-013",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-018",
                            name = "First-019 Surname-013",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-032",
                            name = "First-033 Surname-030",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-031",
                            name = "First-032 Surname-029",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-055",
                            name = "First-055 Surname-049",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-002",
                            name = "First-003 Surname-003",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-014",
                            name = "First-015 Surname-015",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-004",
                            name = "First-005 Surname-005",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-043",
                            name = "First-044 Surname-039",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-054",
                            name = "First-054 Surname-048",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-038",
                            name = "First-039 Surname-034",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-044",
                            name = "First-045 Surname-040",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-053",
                            name = "First-053 Surname-047",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-030",
                            name = "First-031 Surname-011",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-023",
                            name = "First-024 Surname-023",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-005",
                            name = "First-006 Surname-006",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-008",
                            name = "First-009 Surname-009",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-001",
                            name = "First-002 Surname-002",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-037",
                            name = "First-038 Surname-014",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-009",
                            name = "First-010 Surname-010",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-026",
                            name = "First-027 Surname-026",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-042",
                            name = "First-043 Surname-038",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-048",
                            name = "First-048 Surname-042",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-036",
                            name = "First-037 Surname-033",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-020",
                            name = "First-021 Surname-020",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-019",
                            name = "First-020 Surname-019",
                        },
                    },
                    sequence = 8,
                    trigger = "GUILD_ROSTER_UPDATE",
                },
                {
                    availability = {
                        guildRosterMemberCount = true,
                        guildRosterOnlineCount = true,
                        memberListCount = true,
                    },
                    errors = {
                    },
                    guild = {
                        availability = {
                            clubId = true,
                            memberCount = true,
                            name = true,
                            realm = false,
                        },
                        clubId = "Club-001",
                        memberCount = 56,
                        name = "Guild-001",
                    },
                    guildRosterMemberCount = 56,
                    guildRosterOnlineCount = 3,
                    memberListCount = 56,
                    memberSource = "club",
                    members = {
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-001",
                            name = "First-002 Surname-002",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-002",
                            name = "First-003 Surname-003",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-003",
                            name = "First-004 Surname-004",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-004",
                            name = "First-005 Surname-005",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-005",
                            name = "First-006 Surname-006",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-006",
                            name = "First-007 Surname-007",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-007",
                            name = "First-008 Surname-008",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-008",
                            name = "First-009 Surname-009",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-009",
                            name = "First-010 Surname-010",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-010",
                            name = "First-011 Surname-011",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-011",
                            name = "First-012 Surname-012",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-012",
                            name = "First-013 Surname-013",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-013",
                            name = "First-014 Surname-014",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-014",
                            name = "First-015 Surname-015",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-015",
                            name = "First-016 Surname-016",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-016",
                            name = "First-017 Surname-017",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-017",
                            name = "First-018 Surname-018",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-018",
                            name = "First-019 Surname-013",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-019",
                            name = "First-020 Surname-019",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-020",
                            name = "First-021 Surname-020",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-021",
                            name = "First-022 Surname-021",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-022",
                            name = "First-023 Surname-022",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-023",
                            name = "First-024 Surname-023",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-024",
                            name = "First-025 Surname-024",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-025",
                            name = "First-026 Surname-025",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-026",
                            name = "First-027 Surname-026",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-027",
                            name = "First-028 Surname-010",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-028",
                            name = "First-029 Surname-027",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-029",
                            name = "First-030 Surname-028",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-030",
                            name = "First-031 Surname-011",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-031",
                            name = "First-032 Surname-029",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-032",
                            name = "First-033 Surname-030",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-033",
                            name = "First-034 Surname-014",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-034",
                            name = "First-035 Surname-031",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-035",
                            name = "First-036 Surname-032",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-036",
                            name = "First-037 Surname-033",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-037",
                            name = "First-038 Surname-014",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-038",
                            name = "First-039 Surname-034",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-039",
                            name = "First-040 Surname-035",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-040",
                            name = "First-041 Surname-036",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-041",
                            name = "First-042 Surname-037",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-042",
                            name = "First-043 Surname-038",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-043",
                            name = "First-044 Surname-039",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-044",
                            name = "First-045 Surname-040",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-045",
                            name = "First-046 Surname-021",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-046",
                            name = "First-047 Surname-041",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-047",
                            name = "First-001 Surname-001",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-048",
                            name = "First-048 Surname-042",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-049",
                            name = "First-049 Surname-043",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-050",
                            name = "First-050 Surname-044",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-051",
                            name = "First-051 Surname-045",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-052",
                            name = "First-052 Surname-046",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-053",
                            name = "First-053 Surname-047",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-054",
                            name = "First-054 Surname-048",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-055",
                            name = "First-055 Surname-049",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-056",
                            name = "First-056 Surname-050",
                        },
                    },
                    sequence = 9,
                    trigger = "CLUB_MEMBERS_UPDATED",
                },
                {
                    availability = {
                        guildRosterMemberCount = true,
                        guildRosterOnlineCount = true,
                        memberListCount = true,
                    },
                    errors = {
                    },
                    guild = {
                        availability = {
                            clubId = true,
                            memberCount = true,
                            name = true,
                            realm = false,
                        },
                        clubId = "Club-001",
                        memberCount = 56,
                        name = "Guild-001",
                    },
                    guildRosterMemberCount = 56,
                    guildRosterOnlineCount = 3,
                    memberListCount = 56,
                    memberSource = "club",
                    members = {
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-001",
                            name = "First-002 Surname-002",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-002",
                            name = "First-003 Surname-003",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-003",
                            name = "First-004 Surname-004",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-004",
                            name = "First-005 Surname-005",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-005",
                            name = "First-006 Surname-006",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-006",
                            name = "First-007 Surname-007",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-007",
                            name = "First-008 Surname-008",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-008",
                            name = "First-009 Surname-009",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-009",
                            name = "First-010 Surname-010",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-010",
                            name = "First-011 Surname-011",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-011",
                            name = "First-012 Surname-012",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-012",
                            name = "First-013 Surname-013",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-013",
                            name = "First-014 Surname-014",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-014",
                            name = "First-015 Surname-015",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-015",
                            name = "First-016 Surname-016",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-016",
                            name = "First-017 Surname-017",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-017",
                            name = "First-018 Surname-018",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-018",
                            name = "First-019 Surname-013",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-019",
                            name = "First-020 Surname-019",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-020",
                            name = "First-021 Surname-020",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-021",
                            name = "First-022 Surname-021",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-022",
                            name = "First-023 Surname-022",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-023",
                            name = "First-024 Surname-023",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-024",
                            name = "First-025 Surname-024",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-025",
                            name = "First-026 Surname-025",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-026",
                            name = "First-027 Surname-026",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-027",
                            name = "First-028 Surname-010",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-028",
                            name = "First-029 Surname-027",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-029",
                            name = "First-030 Surname-028",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-030",
                            name = "First-031 Surname-011",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-031",
                            name = "First-032 Surname-029",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-032",
                            name = "First-033 Surname-030",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-033",
                            name = "First-034 Surname-014",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-034",
                            name = "First-035 Surname-031",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-035",
                            name = "First-036 Surname-032",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-036",
                            name = "First-037 Surname-033",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-037",
                            name = "First-038 Surname-014",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-038",
                            name = "First-039 Surname-034",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-039",
                            name = "First-040 Surname-035",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-040",
                            name = "First-041 Surname-036",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-041",
                            name = "First-042 Surname-037",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-042",
                            name = "First-043 Surname-038",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-043",
                            name = "First-044 Surname-039",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-044",
                            name = "First-045 Surname-040",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-045",
                            name = "First-046 Surname-021",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-046",
                            name = "First-047 Surname-041",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-047",
                            name = "First-001 Surname-001",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-048",
                            name = "First-048 Surname-042",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-049",
                            name = "First-049 Surname-043",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-050",
                            name = "First-050 Surname-044",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-051",
                            name = "First-051 Surname-045",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-052",
                            name = "First-052 Surname-046",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-053",
                            name = "First-053 Surname-047",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-054",
                            name = "First-054 Surname-048",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-055",
                            name = "First-055 Surname-049",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-056",
                            name = "First-056 Surname-050",
                        },
                    },
                    sequence = 10,
                    trigger = "INITIAL_CLUBS_LOADED",
                },
                {
                    availability = {
                        guildRosterMemberCount = true,
                        guildRosterOnlineCount = true,
                        memberListCount = true,
                    },
                    errors = {
                    },
                    guild = {
                        availability = {
                            clubId = true,
                            memberCount = true,
                            name = true,
                            realm = false,
                        },
                        clubId = "Club-001",
                        memberCount = 56,
                        name = "Guild-001",
                    },
                    guildRosterMemberCount = 56,
                    guildRosterOnlineCount = 3,
                    memberListCount = 56,
                    memberSource = "club",
                    members = {
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-001",
                            name = "First-002 Surname-002",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-002",
                            name = "First-003 Surname-003",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-003",
                            name = "First-004 Surname-004",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-004",
                            name = "First-005 Surname-005",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-005",
                            name = "First-006 Surname-006",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-006",
                            name = "First-007 Surname-007",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-007",
                            name = "First-008 Surname-008",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-008",
                            name = "First-009 Surname-009",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-009",
                            name = "First-010 Surname-010",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-010",
                            name = "First-011 Surname-011",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-011",
                            name = "First-012 Surname-012",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-012",
                            name = "First-013 Surname-013",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-013",
                            name = "First-014 Surname-014",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-014",
                            name = "First-015 Surname-015",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-015",
                            name = "First-016 Surname-016",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-016",
                            name = "First-017 Surname-017",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-017",
                            name = "First-018 Surname-018",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-018",
                            name = "First-019 Surname-013",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-019",
                            name = "First-020 Surname-019",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-020",
                            name = "First-021 Surname-020",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-021",
                            name = "First-022 Surname-021",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-022",
                            name = "First-023 Surname-022",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-023",
                            name = "First-024 Surname-023",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-024",
                            name = "First-025 Surname-024",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-025",
                            name = "First-026 Surname-025",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-026",
                            name = "First-027 Surname-026",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-027",
                            name = "First-028 Surname-010",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-028",
                            name = "First-029 Surname-027",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-029",
                            name = "First-030 Surname-028",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-030",
                            name = "First-031 Surname-011",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-031",
                            name = "First-032 Surname-029",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-032",
                            name = "First-033 Surname-030",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-033",
                            name = "First-034 Surname-014",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-034",
                            name = "First-035 Surname-031",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-035",
                            name = "First-036 Surname-032",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-036",
                            name = "First-037 Surname-033",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-037",
                            name = "First-038 Surname-014",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-038",
                            name = "First-039 Surname-034",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-039",
                            name = "First-040 Surname-035",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-040",
                            name = "First-041 Surname-036",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-041",
                            name = "First-042 Surname-037",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-042",
                            name = "First-043 Surname-038",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-043",
                            name = "First-044 Surname-039",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-044",
                            name = "First-045 Surname-040",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-045",
                            name = "First-046 Surname-021",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-046",
                            name = "First-047 Surname-041",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-047",
                            name = "First-001 Surname-001",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-048",
                            name = "First-048 Surname-042",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-049",
                            name = "First-049 Surname-043",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-050",
                            name = "First-050 Surname-044",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-051",
                            name = "First-051 Surname-045",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-052",
                            name = "First-052 Surname-046",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-053",
                            name = "First-053 Surname-047",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-054",
                            name = "First-054 Surname-048",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-055",
                            name = "First-055 Surname-049",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-056",
                            name = "First-056 Surname-050",
                        },
                    },
                    sequence = 11,
                    trigger = "MANUAL_SNAPSHOT",
                },
                {
                    availability = {
                        guildRosterMemberCount = true,
                        guildRosterOnlineCount = true,
                        memberListCount = true,
                    },
                    errors = {
                    },
                    guild = {
                        availability = {
                            clubId = true,
                            memberCount = true,
                            name = true,
                            realm = false,
                        },
                        clubId = "Club-001",
                        memberCount = 56,
                        name = "Guild-001",
                    },
                    guildRosterMemberCount = 56,
                    guildRosterOnlineCount = 3,
                    memberListCount = 56,
                    memberSource = "club",
                    members = {
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-001",
                            name = "First-002 Surname-002",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-002",
                            name = "First-003 Surname-003",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-003",
                            name = "First-004 Surname-004",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-004",
                            name = "First-005 Surname-005",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-005",
                            name = "First-006 Surname-006",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-006",
                            name = "First-007 Surname-007",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-007",
                            name = "First-008 Surname-008",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-008",
                            name = "First-009 Surname-009",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-009",
                            name = "First-010 Surname-010",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-010",
                            name = "First-011 Surname-011",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-011",
                            name = "First-012 Surname-012",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-012",
                            name = "First-013 Surname-013",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-013",
                            name = "First-014 Surname-014",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-014",
                            name = "First-015 Surname-015",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-015",
                            name = "First-016 Surname-016",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-016",
                            name = "First-017 Surname-017",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-017",
                            name = "First-018 Surname-018",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-018",
                            name = "First-019 Surname-013",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-019",
                            name = "First-020 Surname-019",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-020",
                            name = "First-021 Surname-020",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-021",
                            name = "First-022 Surname-021",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-022",
                            name = "First-023 Surname-022",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-023",
                            name = "First-024 Surname-023",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-024",
                            name = "First-025 Surname-024",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-025",
                            name = "First-026 Surname-025",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-026",
                            name = "First-027 Surname-026",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-027",
                            name = "First-028 Surname-010",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-028",
                            name = "First-029 Surname-027",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-029",
                            name = "First-030 Surname-028",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-030",
                            name = "First-031 Surname-011",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-031",
                            name = "First-032 Surname-029",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-032",
                            name = "First-033 Surname-030",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-033",
                            name = "First-034 Surname-014",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-034",
                            name = "First-035 Surname-031",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-035",
                            name = "First-036 Surname-032",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-036",
                            name = "First-037 Surname-033",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-037",
                            name = "First-038 Surname-014",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-038",
                            name = "First-039 Surname-034",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-039",
                            name = "First-040 Surname-035",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-040",
                            name = "First-041 Surname-036",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-041",
                            name = "First-042 Surname-037",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-042",
                            name = "First-043 Surname-038",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-043",
                            name = "First-044 Surname-039",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-044",
                            name = "First-045 Surname-040",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-045",
                            name = "First-046 Surname-021",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-046",
                            name = "First-047 Surname-041",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-047",
                            name = "First-001 Surname-001",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-048",
                            name = "First-048 Surname-042",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-049",
                            name = "First-049 Surname-043",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-050",
                            name = "First-050 Surname-044",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-051",
                            name = "First-051 Surname-045",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-052",
                            name = "First-052 Surname-046",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-053",
                            name = "First-053 Surname-047",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-054",
                            name = "First-054 Surname-048",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-055",
                            name = "First-055 Surname-049",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-056",
                            name = "First-056 Surname-050",
                        },
                    },
                    sequence = 12,
                    trigger = "GUILD_ROSTER_UPDATE",
                },
                {
                    availability = {
                        guildRosterMemberCount = true,
                        guildRosterOnlineCount = true,
                        memberListCount = true,
                    },
                    errors = {
                    },
                    guild = {
                        availability = {
                            clubId = true,
                            memberCount = true,
                            name = true,
                            realm = false,
                        },
                        clubId = "Club-001",
                        memberCount = 56,
                        name = "Guild-001",
                    },
                    guildRosterMemberCount = 56,
                    guildRosterOnlineCount = 3,
                    memberListCount = 56,
                    memberSource = "club",
                    members = {
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-001",
                            name = "First-002 Surname-002",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-002",
                            name = "First-003 Surname-003",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-003",
                            name = "First-004 Surname-004",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-004",
                            name = "First-005 Surname-005",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-005",
                            name = "First-006 Surname-006",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-006",
                            name = "First-007 Surname-007",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-007",
                            name = "First-008 Surname-008",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-008",
                            name = "First-009 Surname-009",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-009",
                            name = "First-010 Surname-010",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-010",
                            name = "First-011 Surname-011",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-011",
                            name = "First-012 Surname-012",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-012",
                            name = "First-013 Surname-013",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-013",
                            name = "First-014 Surname-014",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-014",
                            name = "First-015 Surname-015",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-015",
                            name = "First-016 Surname-016",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-016",
                            name = "First-017 Surname-017",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-017",
                            name = "First-018 Surname-018",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-018",
                            name = "First-019 Surname-013",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-019",
                            name = "First-020 Surname-019",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-020",
                            name = "First-021 Surname-020",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-021",
                            name = "First-022 Surname-021",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-022",
                            name = "First-023 Surname-022",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-023",
                            name = "First-024 Surname-023",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-024",
                            name = "First-025 Surname-024",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-025",
                            name = "First-026 Surname-025",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-026",
                            name = "First-027 Surname-026",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-027",
                            name = "First-028 Surname-010",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-028",
                            name = "First-029 Surname-027",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-029",
                            name = "First-030 Surname-028",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-030",
                            name = "First-031 Surname-011",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-031",
                            name = "First-032 Surname-029",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-032",
                            name = "First-033 Surname-030",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-033",
                            name = "First-034 Surname-014",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-034",
                            name = "First-035 Surname-031",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-035",
                            name = "First-036 Surname-032",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-036",
                            name = "First-037 Surname-033",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-037",
                            name = "First-038 Surname-014",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-038",
                            name = "First-039 Surname-034",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-039",
                            name = "First-040 Surname-035",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-040",
                            name = "First-041 Surname-036",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-041",
                            name = "First-042 Surname-037",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-042",
                            name = "First-043 Surname-038",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-043",
                            name = "First-044 Surname-039",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-044",
                            name = "First-045 Surname-040",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-045",
                            name = "First-046 Surname-021",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-046",
                            name = "First-047 Surname-041",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-047",
                            name = "First-001 Surname-001",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-048",
                            name = "First-048 Surname-042",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-049",
                            name = "First-049 Surname-043",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-050",
                            name = "First-050 Surname-044",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-051",
                            name = "First-051 Surname-045",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-052",
                            name = "First-052 Surname-046",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-053",
                            name = "First-053 Surname-047",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-054",
                            name = "First-054 Surname-048",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-055",
                            name = "First-055 Surname-049",
                        },
                        {
                            availability = {
                                guid = true,
                                name = true,
                            },
                            guid = "Guid-056",
                            name = "First-056 Surname-050",
                        },
                    },
                    sequence = 13,
                    trigger = "PROBE_STOP",
                },
            },
            runtime = {
                availability = {
                    build = true,
                    interface = true,
                    normalizedRealmName = false,
                    playerName = true,
                    playerRealm = true,
                    productId = true,
                    realmName = true,
                    region = true,
                    version = true,
                },
                build = "70888",
                errors = {
                    "GET_NORMALIZED_REALM_NAME_UNAVAILABLE",
                },
                interface = 16001,
                playerName = "First-001 Surname-001",
                playerRealm = "Realm-003",
                productId = 18,
                realmName = "Realm-001",
                region = "US",
                version = "1.60.1",
            },
        },
    },
    truncated = false,
}
