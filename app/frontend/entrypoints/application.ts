import collapse from "@alpinejs/collapse";
import focus from "@alpinejs/focus";
import persist from "@alpinejs/persist";
import Alpine from '@alpinejs/csp'
import { Application } from "@hotwired/stimulus";
import Sortable from "@stimulus-components/sortable";
import { registerControllers } from "stimulus-vite-helpers";
import "@hotwired/turbo";
import "trix";
import "@rails/actiontext";

Alpine.plugin(collapse);
Alpine.plugin(focus);
Alpine.plugin(persist);

const application = Application.start();
application.register("sortable", Sortable);
const controllers = import.meta.glob("../controllers/**/*_controller.js", { eager: true });
registerControllers(application, controllers);

// Add magic method to easily be able to post data to the backend
Alpine.magic("post", () => {
  return (url, data) =>
    fetch(url, {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
      },
      body: JSON.stringify({
        authenticity_token: window.csrfToken,
        ...data,
      }),
    });
});

Alpine.data('groupManager', () => ({
  deleteGroup() {
    if (window.confirm('Are you sure? This will also delete all the content in this group')) {
      this.$refs.deleteForm.requestSubmit();
    }
  },

  logOut() {
    this.$refs.logoutForm.requestSubmit();
  }
}))

const COOKIE_CONSENT_COOKIE = "cookie_consent";
const ONE_YEAR_SECONDS = 60 * 60 * 24 * 365;

function readCookie(name: string): string | null {
  const match = document.cookie.match(new RegExp(`(?:^|; )${name}=([^;]*)`));
  return match ? decodeURIComponent(match[1]) : null;
}

function writeCookie(name: string, value: string, maxAgeSeconds: number) {
  document.cookie = `${name}=${encodeURIComponent(value)}; path=/; max-age=${maxAgeSeconds}; Secure; SameSite=Lax`;
}

function readStoredConsent(): { analytics: boolean; marketing: boolean; statistical: boolean } | null {
  const raw = readCookie(COOKIE_CONSENT_COOKIE);
  if (!raw) return null;
  try {
    return JSON.parse(raw);
  } catch {
    return null;
  }
}

function gtag(...args: unknown[]) {
  (window as any).dataLayer = (window as any).dataLayer || [];
  (window as any).dataLayer.push(args);
}

function trackConsent(category: string, decision: string) {
  fetch("/cookie_consent", {
    method: "POST",
    keepalive: true,
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify({ page: window.location.pathname, category, decision }),
  });
}

function clearCookie(name: string) {
  document.cookie = `${name}=; expires=Thu, 01 Jan 1970 00:00:00 GMT; path=/; domain=.${location.hostname.replace(/^www\./, "")}`;
}

function loadTikTokPixel() {
  !(function (w: any, d: Document, t: string) {
    w.TiktokAnalyticsObject = t;
    const ttq = (w[t] = w[t] || []);
    ttq.methods = ["page", "track", "identify", "instances", "debug", "on", "off", "once", "ready", "alias", "group", "enableCookie", "disableCookie", "holdConsent", "revokeConsent", "grantConsent"];
    ttq.setAndDefer = function (target: any, method: string) {
      target[method] = function (...args: unknown[]) {
        target.push([method].concat(Array.prototype.slice.call(args, 0)));
      };
    };
    for (let i = 0; i < ttq.methods.length; i++) ttq.setAndDefer(ttq, ttq.methods[i]);
    ttq.instance = function (target: string) {
      const e = ttq._i[target] || [];
      for (let n = 0; n < ttq.methods.length; n++) ttq.setAndDefer(e, ttq.methods[n]);
      return e;
    };
    ttq.load = function (e: string, n: any) {
      const r = "https://analytics.tiktok.com/i18n/pixel/events.js";
      const o = n && n.partner;
      ttq._i = ttq._i || {};
      ttq._i[e] = [];
      ttq._i[e]._u = r;
      ttq._t = ttq._t || {};
      ttq._t[e] = +new Date();
      ttq._o = ttq._o || {};
      ttq._o[e] = n || {};
      const script = document.createElement("script");
      script.type = "text/javascript";
      script.async = true;
      script.src = r + "?sdkid=" + e + "&lib=" + t;
      const first = document.getElementsByTagName("script")[0];
      first.parentNode?.insertBefore(script, first);
    };
  })(window, document, "ttq");
  (window as any).ttq.load("D7TJP6RC77U9E9A36HLG");
  (window as any).ttq.page();
}

Alpine.store("cookieConsent", {
  visible: false,
  showSettings: false,
  analytics: false,
  marketing: false,
  statistical: true,

  init() {
    const saved = readStoredConsent();
    if (saved) {
      this.analytics = !!saved.analytics;
      this.marketing = !!saved.marketing;
      this.statistical = saved.statistical !== false;
      this.applyAll(false);
    } else {
      this.visible = true;
    }
  },

  persist() {
    writeCookie(
      COOKIE_CONSENT_COOKIE,
      JSON.stringify({ analytics: this.analytics, marketing: this.marketing, statistical: this.statistical }),
      ONE_YEAR_SECONDS,
    );
  },

  applyAnalytics(track: boolean) {
    if (this.analytics) {
      gtag("consent", "update", { analytics_storage: "granted" });
      (window as any)._analyticsConsented = true;
      gtag("event", "analytics_accept");
      if (track) trackConsent("analytics", "accepted");
    } else {
      gtag("consent", "update", { analytics_storage: "denied" });
      (window as any)._analyticsConsented = false;
      if (track) trackConsent("analytics", "declined");
    }
  },

  applyMarketing(track: boolean) {
    if (this.marketing) {
      gtag("consent", "update", { ad_storage: "granted", ad_user_data: "granted", ad_personalization: "granted" });
      gtag("event", "marketing_accept");
      if (track) trackConsent("marketing", "accepted");
      loadTikTokPixel();
    } else {
      gtag("consent", "update", { ad_storage: "denied", ad_user_data: "denied", ad_personalization: "denied" });
      if (track) trackConsent("marketing", "declined");
      if (typeof (window as any).fbq === "function") (window as any).fbq("consent", "revoke");
      if (typeof (window as any).ttq !== "undefined") (window as any).ttq.revokeConsent();
      ["_rdt_uuid", "_ttp", "_tt_enable_cookie", "_fbp"].forEach(clearCookie);
    }
  },

  applyStatistical(track: boolean) {
    if (this.statistical) {
      if (track) trackConsent("statistical", "accepted");
      document.cookie = "ahoy_dnt=; path=/; max-age=0; Secure; SameSite=Lax";
    } else {
      if (track) trackConsent("statistical", "revoked");
      document.cookie = `ahoy_dnt=1; path=/; max-age=${ONE_YEAR_SECONDS}; Secure; SameSite=Lax`;
    }
  },

  applyAll(track: boolean) {
    this.applyAnalytics(track);
    this.applyMarketing(track);
    this.applyStatistical(track);
  },

  acceptAll() {
    this.analytics = true;
    this.marketing = true;
    this.statistical = true;
    this.applyAll(true);
    this.persist();
    this.visible = false;
    this.showSettings = false;
  },

  rejectAll() {
    this.analytics = false;
    this.marketing = false;
    this.statistical = false;
    this.applyAll(true);
    this.persist();
    this.visible = false;
    this.showSettings = false;
  },

  dismiss() {
    trackConsent("banner", "dismissed");
    this.visible = false;
    this.showSettings = false;
  },

  openSettings() {
    this.showSettings = true;
    this.visible = true;
  },

  saveSettings() {
    this.applyAll(true);
    this.persist();
    this.visible = false;
    this.showSettings = false;
  },
});

Alpine.data('noneOfTheAbove', () => {
  const NONE_PHRASES = ["None of the above", "Dim un o’r rhain"];
  let noneCheckbox: HTMLInputElement | null = null;
  let otherCheckboxes: HTMLInputElement[] = [];

  const applyState = (root: HTMLElement) => {
    if (!noneCheckbox) return;
    const noneActive = noneCheckbox.checked;
    otherCheckboxes.forEach((cb) => {
      cb.disabled = noneActive;
      const associated = cb.id ? root.querySelector<HTMLElement>(`label[for="${cb.id}"]`) : null;
      const wrapping = cb.closest<HTMLElement>('label');
      ([cb, associated, wrapping].filter(Boolean) as HTMLElement[]).forEach((el) => {
        el.classList.toggle('opacity-50', noneActive);
        el.classList.toggle('cursor-not-allowed', noneActive);
      });
    });
  };

  return {
    init() {
      const root = (this as unknown as { $el: HTMLElement }).$el;
      const checkboxes = Array.from(root.querySelectorAll<HTMLInputElement>('input[type="checkbox"]'));
      const normalisedPhrases = NONE_PHRASES.map((p) => p.trim().toLowerCase());
      noneCheckbox = checkboxes.find((cb) =>
        normalisedPhrases.includes((cb.value || "").trim().toLowerCase())
      ) || null;
      if (!noneCheckbox) return;

      otherCheckboxes = checkboxes.filter((cb) => cb !== noneCheckbox);
      checkboxes.forEach((cb) => {
        cb.addEventListener('change', (event) => {
          const target = event.target as HTMLInputElement;
          if (target === noneCheckbox) {
            if (noneCheckbox.checked) {
              otherCheckboxes.forEach((other) => { other.checked = false; });
            }
          } else if (target.checked && noneCheckbox) {
            noneCheckbox.checked = false;
          }
          applyState(root);
        });
      });
      applyState(root);
    }
  };
})

window.Alpine = Alpine;
Alpine.start();

// Parses a Ruby base-64 encoded JSON
window.parseB64Json = (encodedString) => {
  const baseString = atob(encodedString);

  // Properly decode UTF-8 characters
  const utfString = decodeURIComponent(
    baseString
      .split("")
      .map((char) => `%${char.charCodeAt(0).toString(16).padStart(2, "0")}`)
      .join(""),
  );

  return JSON.parse(utfString);
};

// Add magic method to easily decode base64 encoded JSON
Alpine.magic("json", () => {
  return (encodedString) => window.parseB64Json(encodedString);
});

document.addEventListener("turbo:load", (event) => {
  window.dataLayer = window.dataLayer || [];
  function gtag(){dataLayer.push(arguments);}
  gtag('js', new Date());
  gtag('config', 'GTM-NWN4JM5J');
})
