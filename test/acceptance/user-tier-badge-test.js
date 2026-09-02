import { visit } from "@ember/test-helpers";
import { test } from "qunit";
import { acceptance } from "discourse/tests/helpers/qunit-helpers";

acceptance("User Tier Badge | tier progress", function (needs) {
  needs.user({
    id: 1,
    name: "Alice",
    username: "alice",
    avatar_template: "/user_avatar/localhost/alice/{size}/1.png",
    groups: [],
  });

  needs.pretender((server, helper) => {
    server.get("/user-badges/alice.json", () =>
      helper.response({
        badges: [{ id: 10 }, { id: 11 }, { id: 20 }],
        user_badges: [],
      })
    );

    server.get("/leaderboard", () =>
      helper.response({
        personal: { user: { id: 1, total_score: 0 } },
      })
    );
  });

  needs.site({
    groups: [
      { id: 41, name: "tl1" },
      { id: 42, name: "tl2" },
      { id: 43, name: "tl3" },
    ],
  });

  let originalTiers;

  needs.hooks.beforeEach(function () {
    localStorage.clear();
    originalTiers = settings.tiers;
    settings.tiers = [
      {
        name: "user_badge.tiers.tier_1",
        badge_ids: "10,11",
        group: [41],
      },
      {
        name: "user_badge.tiers.tier_2",
        badge_ids: "20,21,22",
        group: [42],
      },
      {
        name: "user_badge.tiers.tier_3",
        badge_ids: "30,31",
        group: [43],
      },
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

    // Tier 1 (10, 11) is complete. Tier 2 has 20 of 20, 21, 22.
    assert
      .dom(".user-tier-badge__progress progress")
      .hasAttribute("value", "1");
    assert.dom(".user-tier-badge__progress progress").hasAttribute("max", "3");
    assert
      .dom(".user-tier-badge__progress-label a")
      .hasAttribute("href", "/g/tl2");
  });

  test("renders the completion message when all tier groups are held", async function (assert) {
    needs.user({
      id: 1,
      name: "Alice",
      username: "alice",
      avatar_template: "/user_avatar/localhost/alice/{size}/1.png",
      groups: [{ id: 41 }, { id: 42 }, { id: 43 }],
    });

    await visit("/");

    assert.dom(".user-tier-badge__message--done").exists();
    assert
      .dom(".user-tier-badge__message--done")
      .hasText(
        "You have completed every tier. Thank you for being part of this."
      );
  });

  test("renders the almost-there message on the last tier at the karma goal without the second badge", async function (assert) {
    needs.user({
      id: 1,
      name: "Alice",
      username: "alice",
      avatar_template: "/user_avatar/localhost/alice/{size}/1.png",
      groups: [{ id: 41 }, { id: 42 }],
    });

    needs.pretender((server, helper) => {
      server.get("/user-badges/alice.json", () =>
        helper.response({
          badges: [
            { id: 10 },
            { id: 11 },
            { id: 20 },
            { id: 21 },
            { id: 22 },
            { id: 30 },
          ],
          user_badges: [],
        })
      );

      server.get("/leaderboard", () =>
        helper.response({
          personal: { user: { id: 1, total_score: 9999 } },
        })
      );
    });

    await visit("/");

    assert.dom(".user-tier-badge__message--almost").exists();
    assert
      .dom(".user-tier-badge__message--almost")
      .hasText("You are very close, just think outside the box");
  });

  test("shows last tier progress when karma badge not yet earned", async function (assert) {
    needs.user({
      id: 1,
      name: "Alice",
      username: "alice",
      avatar_template: "/user_avatar/localhost/alice/{size}/1.png",
      groups: [{ id: 41 }, { id: 42 }],
    });

    needs.pretender((server, helper) => {
      server.get("/user-badges/alice.json", () =>
        helper.response({
          badges: [{ id: 10 }, { id: 11 }, { id: 20 }, { id: 21 }, { id: 22 }],
          user_badges: [],
        })
      );

      server.get("/leaderboard", () =>
        helper.response({
          personal: { user: { id: 1, total_score: 1234 } },
        })
      );
    });

    await visit("/");

    assert
      .dom(".user-tier-badge__progress progress")
      .hasAttribute("value", "0");
    assert.dom(".user-tier-badge__progress progress").hasAttribute("max", "2");
  });
});
