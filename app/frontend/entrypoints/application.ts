import collapse from "@alpinejs/collapse";
import focus from "@alpinejs/focus";
import persist from "@alpinejs/persist";
import Alpine from "alpinejs";
import "./application.css";

Alpine.plugin(collapse);
Alpine.plugin(focus);
Alpine.plugin(persist);

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
