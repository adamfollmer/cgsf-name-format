// Client mirror of CgsfNameFormat.normalize in plugin.rb, so the signup preview
// shows exactly the name the server will save: "maria garcia" -> "Maria G.".

function capitalize(word) {
  if (!word) {
    return word;
  }
  if (word === word.toLowerCase() || word === word.toUpperCase()) {
    return word[0].toUpperCase() + word.slice(1).toLowerCase();
  }
  return word[0].toUpperCase() + word.slice(1);
}

// Returns null when there is nothing to shape yet (fewer than two words).
export function shortName(raw) {
  const words = (raw || "").trim().split(/\s+/).filter(Boolean);
  if (words.length < 2) {
    return null;
  }

  const initial = words.pop().match(/\p{L}/u)?.[0];
  if (!initial) {
    return null;
  }

  const given = words.map((w) => w.split("-").map(capitalize).join("-"));
  return `${given.join(" ")} ${initial.toUpperCase()}.`;
}

// True when the last word is longer than an initial, i.e. we will shorten it.
export function willShorten(raw) {
  const words = (raw || "").trim().split(/\s+/).filter(Boolean);
  if (words.length < 2) {
    return false;
  }
  return (words.at(-1).match(/\p{L}/gu) || []).length > 1;
}
