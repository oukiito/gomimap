// SPDX-License-Identifier: GPL-3.0-or-later
// Matching files are served by Static Assets without invoking this module.
export default {
  fetch() {
    return new Response("Not found\n", {
      status: 404,
      headers: {
        "Content-Type": "text/plain; charset=utf-8",
        "Cache-Control": "no-store",
        "Access-Control-Allow-Origin": "*",
        "X-Content-Type-Options": "nosniff",
      },
    });
  },
};
