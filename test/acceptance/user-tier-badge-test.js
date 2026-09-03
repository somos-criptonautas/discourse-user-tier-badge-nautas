import { visit } from "@ember/test-helpers";
import { test } from "qunit";
import { acceptance } from "discourse/tests/helpers/qunit-helpers";

const ALICE = {
  id: 1,
  name: "Alice",
  username: "alice",
  avatar_template: "/user_avatar/localhost/alice/{size}/1.png",
  groups: [],
};

// Every badge referenced by the tiers below, so the checklist can name and
// link the ones Alice has not earned.
const SITE_BADGES = [10, 11, 20, 21, 22, 30, 31].map((id) => ({
  id,
  name: `Badge ${id}`,
  slug: `badge-${id}`,
}));

function stubUserBadges(server, helper, ids) {
  server.get("/user-badges/alice.json", () =>
    helper.response({
      badges: ids.map((id) => ({ id })),
      user_badges: [],
    })
  );
}

function stubKarma(server, helper, score) {
  server.get("/leaderboard", () =>
    helper.response({ personal: { user: { id: 1, total_score: score } } })
  );
}

acceptance("User Tier Badge | tier progress", function (needs) {
  needs.user(ALICE);

  needs.site({
    groups: [
      { id: 41, name: "tl1" },
      { id: 42, name: "tl2" },
      { id: 43, name: "tl3" },
    ],
  });

  needs.pretender((server, helper) => {
    server.get("/badges.json", () => helper.response({ badges: SITE_BADGES }));

    server.get("/u/alice/summary.json", () =>
      helper.response({
        user_summary: { post_count: 42, likes_received: 17 },
      })
    );

    stubUserBadges(server, helper, [10, 11, 20]);
    stubKarma(server, helper, 0);
  });

  let originalTiers;

  needs.hooks.beforeEach(function () {
    localStorage.clear();
    originalTiers = settings.tiers;
    settings.tiers = [
      { name: "user_badge.tiers.tier_1", badge_ids: "10,11", group: [41] },
      { name: "user_badge.tiers.tier_2", badge_ids: "20,21,22", group: [42] },
      { name: "user_badge.tiers.tier_3", badge_ids: "30,31", group: [43] },
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

  test("shows posts and likes, and hides karma when gamification is absent", async function (assert) {
    await visit("/");

    assert.dom(".user-tier-badge__stats").exists();
    assert.dom(".user-tier-badge__stat").exists({ count: 2 });
    assert
      .dom(".user-tier-badge__stat:first-child .user-tier-badge__stat-value")
      .hasText("42");
  });

  test("advances to the first tier whose badges are not all earned", async function (assert) {
    await visit("/");

    // Tier 1 (10, 11) is complete, so tier 2 (20, 21, 22) is shown with 20 of 3.
    assert
      .dom(".user-tier-badge__progress progress")
      .hasAttribute("value", "1");
    assert.dom(".user-tier-badge__progress progress").hasAttribute("max", "3");
  });

  test("links the tier name to the group that unlocks it", async function (assert) {
    await visit("/");

    assert
      .dom(".user-tier-badge__progress-label a")
      .hasAttribute("href", "/g/tl2");
  });

  test("ticks earned badges and links every row to the badge", async function (assert) {
    await visit("/");

    assert.dom(".user-tier-badge__requirement").exists({ count: 3 });
    assert
      .dom(".user-tier-badge__requirement.--earned")
      .exists({ count: 1 }, "only badge 20 is earned in tier 2");
    assert.dom(".user-tier-badge__requirement.--missing").exists({ count: 2 });
    assert
      .dom(".user-tier-badge__requirement:first-child a")
      .hasAttribute("href", "/badges/20/badge-20");
  });
});

acceptance("User Tier Badge | completed", function (needs) {
  needs.user(ALICE);

  needs.pretender((server, helper) => {
    server.get("/badges.json", () => helper.response({ badges: SITE_BADGES }));
    server.get("/u/alice/summary.json", () =>
      helper.response({ user_summary: { post_count: 42, likes_received: 17 } })
    );
    stubUserBadges(server, helper, [10, 11, 20, 21, 22, 30, 31]);
    stubKarma(server, helper, 12000);
  });

  let originalTiers;

  needs.hooks.beforeEach(function () {
    localStorage.clear();
    originalTiers = settings.tiers;
    settings.tiers = [
      { name: "user_badge.tiers.tier_1", badge_ids: "10,11", group: [41] },
      { name: "user_badge.tiers.tier_2", badge_ids: "20,21,22", group: [42] },
      { name: "user_badge.tiers.tier_3", badge_ids: "30,31", group: [43] },
    ];
  });

  needs.hooks.afterEach(function () {
    settings.tiers = originalTiers;
  });

  test("renders the completion message when every tier's badges are earned", async function (assert) {
    await visit("/");

    assert
      .dom(".user-tier-badge__message--done")
      .hasText(
        "You have completed every tier. Thank you for being part of this."
      );
    assert.dom(".user-tier-badge__requirement").doesNotExist();
  });

  test("shows karma once gamification answers", async function (assert) {
    await visit("/");

    assert.dom(".user-tier-badge__stat").exists({ count: 3 });
  });
});

acceptance("User Tier Badge | almost there", function (needs) {
  needs.user(ALICE);

  needs.pretender((server, helper) => {
    server.get("/badges.json", () => helper.response({ badges: SITE_BADGES }));
    server.get("/u/alice/summary.json", () =>
      helper.response({ user_summary: { post_count: 42, likes_received: 17 } })
    );
    // Last tier: karma badge (30) earned, extraordinary badge (31) not.
    stubUserBadges(server, helper, [10, 11, 20, 21, 22, 30]);
    stubKarma(server, helper, 9999);
  });

  let originalTiers;

  needs.hooks.beforeEach(function () {
    localStorage.clear();
    originalTiers = settings.tiers;
    settings.tiers = [
      { name: "user_badge.tiers.tier_1", badge_ids: "10,11", group: [41] },
      { name: "user_badge.tiers.tier_2", badge_ids: "20,21,22", group: [42] },
      { name: "user_badge.tiers.tier_3", badge_ids: "30,31", group: [43] },
    ];
  });

  needs.hooks.afterEach(function () {
    settings.tiers = originalTiers;
  });

  test("nudges instead of listing the last tier at the karma goal", async function (assert) {
    await visit("/");

    assert
      .dom(".user-tier-badge__message--almost")
      .hasText("You are very close, just think outside the box");
    assert.dom(".user-tier-badge__requirement").doesNotExist();
  });
});

acceptance("User Tier Badge | group granted without badges", function (needs) {
  // Tier 2's group arrived by subscription, so the block skips past it to
  // tier 3 even though none of tier 2's badges are earned.
  needs.user({ ...ALICE, groups: [{ id: 42 }] });

  needs.pretender((server, helper) => {
    server.get("/badges.json", () => helper.response({ badges: SITE_BADGES }));
    server.get("/u/alice/summary.json", () =>
      helper.response({ user_summary: { post_count: 42, likes_received: 17 } })
    );
    stubUserBadges(server, helper, [10, 11]);
    stubKarma(server, helper, 100);
  });

  let originalTiers;

  needs.hooks.beforeEach(function () {
    localStorage.clear();
    originalTiers = settings.tiers;
    settings.tiers = [
      { name: "user_badge.tiers.tier_1", badge_ids: "10,11", group: [41] },
      { name: "user_badge.tiers.tier_2", badge_ids: "20,21,22", group: [42] },
      { name: "user_badge.tiers.tier_3", badge_ids: "30,31", group: [43] },
    ];
  });

  needs.hooks.afterEach(function () {
    settings.tiers = originalTiers;
  });

  test("skips a tier whose group is held", async function (assert) {
    await visit("/");

    assert.dom(".user-tier-badge__requirement").exists({ count: 2 });
    assert
      .dom(".user-tier-badge__requirement:first-child a")
      .hasAttribute("href", "/badges/30/badge-30");
  });
});
