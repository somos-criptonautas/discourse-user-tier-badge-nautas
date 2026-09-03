import { visit } from "@ember/test-helpers";
import { test } from "qunit";
import { acceptance } from "discourse/tests/helpers/qunit-helpers";

const USERS = {
  alice: {
    id: 1,
    username: "alice",
    avatar_template: "/user_avatar/localhost/alice/{size}/1.png",
  },
  bob: {
    id: 2,
    username: "bob",
    avatar_template: "/user_avatar/localhost/bob/{size}/2.png",
  },
};

// granted_at is what orders the list, so every grant here has a distinct one.
const GRANTS = {
  10: [{ user: "bob", granted_at: "2026-09-01T10:00:00.000Z" }],
  11: [{ user: "alice", granted_at: "2026-09-02T10:00:00.000Z" }],
  // Second grant for bob: he must still appear once, on his newest badge.
  20: [{ user: "bob", granted_at: "2026-09-03T10:00:00.000Z" }],
  21: [],
  22: [],
};

function badgeResponse(helper, badgeId) {
  const grants = GRANTS[badgeId] ?? [];

  return helper.response({
    user_badge_info: {
      badges: [
        {
          id: Number(badgeId),
          name: `Badge ${badgeId}`,
          slug: `badge-${badgeId}`,
        },
      ],
      users: grants.map((grant) => USERS[grant.user]),
      user_badges: grants.map((grant, index) => ({
        id: Number(badgeId) * 100 + index,
        badge_id: Number(badgeId),
        user_id: USERS[grant.user].id,
        granted_at: grant.granted_at,
      })),
    },
  });
}

acceptance("User Tier Badge | recent tier badges", function (needs) {
  needs.pretender((server, helper) => {
    server.get("/user_badges.json", (request) =>
      badgeResponse(helper, request.queryParams.badge_id)
    );
  });

  let originalTiers;

  needs.hooks.beforeEach(function () {
    localStorage.clear();
    originalTiers = settings.tiers;
    settings.tiers = [
      { name: "user_badge.tiers.tier_1", badge_ids: "10,11", group: [] },
      { name: "user_badge.tiers.tier_2", badge_ids: "20,21,22", group: [] },
    ];
  });

  needs.hooks.afterEach(function () {
    settings.tiers = originalTiers;
  });

  test("lists one row per member, newest grant first", async function (assert) {
    await visit("/");

    assert
      .dom(".recent-tier-badges__row")
      .exists({ count: 2 }, "bob's two grants collapse to one row");
    assert
      .dom(".recent-tier-badges__row:first-child .recent-tier-badges__username")
      .hasText("bob", "bob's badge 20 is the most recent grant");
    assert
      .dom(".recent-tier-badges__row:first-child .recent-tier-badges__badge")
      .hasAttribute("href", "/badges/20/badge-20");
  });
});

acceptance(
  "User Tier Badge | recent tier badges, unconfigured",
  function (needs) {
    needs.pretender((server, helper) => {
      server.get("/user_badges.json", (request) =>
        badgeResponse(helper, request.queryParams.badge_id)
      );
    });

    let originalTiers;

    needs.hooks.beforeEach(function () {
      localStorage.clear();
      originalTiers = settings.tiers;
      settings.tiers = [
        { name: "user_badge.tiers.tier_1", badge_ids: "", group: [] },
      ];
    });

    needs.hooks.afterEach(function () {
      settings.tiers = originalTiers;
    });

    test("renders nothing when no tier has badge ids", async function (assert) {
      await visit("/");

      assert.dom(".recent-tier-badges__layout").doesNotExist();
    });
  }
);
