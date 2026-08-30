import { visit } from "@ember/test-helpers";
import { test } from "qunit";
import { acceptance } from "discourse/tests/helpers/qunit-helpers";

acceptance("User Tier Badge | tier progress", function (needs) {
  needs.user({
    id: 1,
    name: "Alice",
    username: "alice",
    avatar_template: "/user_avatar/localhost/alice/{size}/1.png",
  });

  needs.pretender((server, helper) => {
    server.get("/user-badges/alice.json", () =>
      helper.response({
        badges: [{ id: 10 }, { id: 11 }, { id: 20 }],
        user_badges: [],
      })
    );
  });

  needs.site({
    groups: [
      { id: 41, name: "tl1" },
      { id: 42, name: "tl2" },
    ],
  });

  let originalTiers;

  needs.hooks.beforeEach(function () {
    localStorage.clear();
    originalTiers = settings.tiers;
    settings.tiers = [
      { name: "user_badge.tiers.tier_1", badge_ids: "10,11", group: [41] },
      { name: "user_badge.tiers.tier_2", badge_ids: "20,21,22", group: [42] },
      { name: "user_badge.tiers.tier_3", badge_ids: "", group: [] },
    ];
  });

  needs.hooks.afterEach(function () {
    settings.tiers = originalTiers;
  });

  test("renders the current user's avatar and profile link", async function (assert) {
    await visit("/");

    assert.dom(".user-tier-badge__layout").exists();
    assert.dom(".user-tier-badge__link").hasAttribute("href", "/u/alice");
    assert.dom(".user-tier-badge__name").hasText("Alice");
  });

  test("shows progress for the first unfinished tier", async function (assert) {
    await visit("/");

    // Tier 1 (10, 11) is complete and collapses. Tier 2 has 20 of 20, 21, 22.
    assert
      .dom(".user-tier-badge__progress progress")
      .hasAttribute("value", "1");
    assert.dom(".user-tier-badge__progress progress").hasAttribute("max", "3");
    assert
      .dom(".user-tier-badge__progress-label a")
      .hasAttribute("href", "/g/tl2");
  });
});
