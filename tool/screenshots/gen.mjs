// Generates a fictional YouTube Takeout, the app's cache seed, and specs
// for the channel pictures and thumbnails. Everything here is made up.
import fs from 'node:fs';
import path from 'node:path';
import { crc32 } from 'node:zlib';

import { WORK } from './common.mjs';

const OUT = WORK;
fs.rmSync(OUT, { recursive: true, force: true });
fs.mkdirSync(OUT, { recursive: true });

let seed = 20260927;
const rand = () => {
  seed |= 0; seed = (seed + 0x6d2b79f5) | 0;
  let t = Math.imul(seed ^ (seed >>> 15), 1 | seed);
  t = (t + Math.imul(t ^ (t >>> 7), 61 | t)) ^ t;
  return ((t ^ (t >>> 14)) >>> 0) / 4294967296;
};
const pick = (a) => a[Math.floor(rand() * a.length)];
const B64 = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-_';
const AZ09 = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789';
const randStr = (n, chars = B64) => Array.from({ length: n }, () => pick([...chars])).join('');
const channelId = () => 'UC' + randStr(22);
const videoId = () => randStr(11);
const commentId = () => 'Ugz' + randStr(20, AZ09) + '4AaABAg';
const liveChatId = () => 'ChwKGkNJ' + randStr(18, AZ09) + 'EFRS' + randStr(4, AZ09);

const ts = (d) => d.toISOString().replace('Z', '').replace(/\.(\d{3})$/, (_, ms) => '.' + ms + randStr(3, '0123456789')) + '+00:00';
const date = (y, m, d, h = 12, mi = 0) =>
  new Date(Date.UTC(y, m - 1, d, h, mi, Math.floor(rand() * 60), Math.floor(rand() * 1000)));

// ---------------------------------------------------------------- channels
const own = { id: channelId(), title: 'Jordan Vale', handle: 'jordanvale', emoji: 'JV', colors: ['#f43f5e', '#8b5cf6'], monogram: true };

const channels = [
  { key: 'bsb', title: 'Byte Sized Builds', emoji: '🔧', colors: ['#0ea5e9', '#6366f1'], videos: [
    'I Built a Weather Station for $12', 'Soldering for Absolute Beginners', 'Why Your 3D Prints Keep Warping',
    'Reviving a Dead Handheld From 1998', 'The $5 Microcontroller That Does Everything', 'Building a Tiny E-Ink Clock'] },
  { key: 'ka', title: 'Kitchen Alchemy', emoji: '🍳', colors: ['#f97316', '#ef4444'], videos: [
    'The Science of the Perfect Crispy Potato', 'Sourdough Without the Stress', '5 Knife Skills That Change Everything',
    'I Cooked Only With a Rice Cooker for a Week'] },
  { key: 'pp', title: 'Pixel Pilgrim', emoji: '🕹️', colors: ['#db2777', '#f59e0b'], videos: [
    'Forgotten Handhelds of the 90s', 'Why Old Game Cartridges Still Work', 'The Strangest Controller Ever Made'] },
  { key: 'on', title: 'Orbital Notes', emoji: '🚀', colors: ['#1e1b4b', '#7c3aed'], videos: [
    'How Big Is the Universe, Really?', 'What Would Happen If You Fell Into Jupiter', 'Every Mars Rover, Ranked'] },
  { key: 'ss', title: 'Speedrun Saturdays', emoji: '⏱️', colors: ['#dc2626', '#f59e0b'], live: true, videos: [
    'World Record Attempts — Any% Marathon 🔴', 'Race Night: 4-Way Relay'] },
  { key: 'll', title: 'Lo-fi Lighthouse', emoji: '🎧', colors: ['#312e81', '#0ea5e9'], live: true, videos: [
    'lofi beats to study and relax to 🌊 24/7', 'rainy night coding session ☔'] },
  { key: 'td', title: 'Trailhead Diaries', emoji: '🥾', colors: ['#16a34a', '#0d9488'], videos: [
    'Solo Overnight on the Ridge Trail', 'My Ultralight Pack Is Under 10 lb', 'Getting Lost (On Purpose) in the Desert'] },
  { key: 'mr', title: 'The Map Room', emoji: '🗺️', colors: ['#a16207', '#fbbf24'], videos: [
    'Why Every Border Looks the Way It Does', 'Tiny Islands With Huge Stories'] },
  { key: 'ptm', title: 'Paper Trail Math', emoji: '📐', colors: ['#0f766e', '#22d3ee'], videos: [
    'The Most Beautiful Equation, Visualized', 'Why 0.999… Equals 1'] },
  { key: 'sl', title: 'Studio Loam', emoji: '🏺', colors: ['#92400e', '#d97706'], videos: [
    'Throwing a Tall Vase in One Take', "Glaze Mistakes I'll Never Make Again"] },
  { key: 'gt', title: 'Garden Theory', emoji: '🌱', colors: ['#15803d', '#84cc16'], videos: [
    'Balcony Tomatoes: Full Season Timelapse', 'Compost, Explained Simply'] },
  { key: 'ms', title: 'Midnight Synth', emoji: '🎹', colors: ['#7e22ce', '#ec4899'], videos: [
    'Driving Through Neon — Full Album'] },
  // Watched, never commented on.
  { key: 'dcr', title: 'Daily Cat Report', emoji: '🐈', colors: ['#f59e0b', '#fde68a'], videos: [
    'Cat Discovers the Dishwasher', 'Weekly Nap Rankings', 'The Great Box Heist'] },
  { key: 'tw', title: 'Tiny Workshop', emoji: '🪚', colors: ['#78350f', '#a3a3a3'], videos: [
    'Making a Walnut Desk Organizer', 'Hand Tools Only: Dovetail Box'] },
  { key: 'fw', title: 'Frame by Frame', emoji: '🎬', colors: ['#111827', '#ef4444'], videos: [
    'How This One Shot Was Filmed', 'The Editing Trick in Every Trailer', 'Practical Effects Still Win'] },
];
const byKey = {};
const videos = {}; // id -> {id, title, channel}
for (const c of channels) {
  c.id = channelId();
  byKey[c.key] = c;
  c.videoIds = c.videos.map((title) => {
    const id = videoId();
    videos[id] = { id, title, channel: c };
    return id;
  });
}
const v = (key, i) => byKey[key].videoIds[i];

// ---------------------------------------------------------------- comments
const people = {
  sparky: { name: '@sparkyelectrons', id: channelId() },
  miso: { name: '@misoandmore', id: channelId() },
  lin: { name: '@lin.codes', id: channelId() },
  trail: { name: '@trailmixtina', id: channelId() },
};
const C = []; // [videoId, date, text, reply?]
const add = (key, vi, d, text, reply) => C.push({ video: v(key, vi), d, text, reply });

add('bsb', 0, date(2025, 3, 14, 18), 'Built this over the weekend with my kid. The humidity sensor tip at 7:42 saved us a lot of head scratching 🙌');
add('bsb', 1, date(2014, 1, 9, 2), 'First!');
add('bsb', 1, date(2014, 1, 9, 3), 'who else is watching this at 3am instead of doing homework');
add('bsb', 1, date(2019, 6, 2, 20), 'Came back to this video after 5 years. Still the best soldering tutorial on here.');
add('bsb', 1, date(2019, 6, 2, 21), 'lead-free solder is fine, you just need a hotter iron', people.sparky);
add('bsb', 2, date(2022, 11, 20, 16), 'Brim + enclosure fixed it for me. Glass bed was the real culprit though.');
add('bsb', 2, date(2022, 11, 21, 9), 'Can you do a follow-up on PETG? Mine strings like crazy');
add('bsb', 3, date(2023, 8, 5, 22), 'Mine had the exact same corroded battery contacts. Vinegar + a toothbrush brought it back to life!');
add('bsb', 3, date(2023, 8, 6, 1), 'The screen replacement part was so satisfying');
add('bsb', 4, date(2024, 2, 18, 15), 'Ordered three of these. My desk is now 40% microcontrollers.');
add('bsb', 4, date(2024, 2, 18, 15, 30), 'Does the deep sleep mode really get under 10µA? That would be perfect for a door sensor', people.lin);
add('bsb', 5, date(2026, 7, 30, 19), 'The partial refresh trick is genius. Stealing this for my calendar display.');
add('bsb', 5, date(2026, 7, 31, 8), 'What font is that on the clock face? It looks great at that size');
add('ka', 0, date(2015, 12, 24, 17), 'First! Making these for Christmas dinner tomorrow');
add('ka', 0, date(2021, 1, 3, 19), 'The baking soda in the boiling water is black magic. Crispiest potatoes of my life.');
add('ka', 1, date(2020, 4, 12, 11), 'Day 6 of lockdown and my starter finally doubled. Named him Clint Yeastwood.');
add('ka', 1, date(2020, 4, 20, 10), 'Update: Clint Yeastwood made his first loaf. It was a brick but a delicious brick 🍞');
add('ka', 1, date(2020, 4, 20, 11), 'try a longer cold proof, mine went from brick to bakery overnight', people.miso);
add('ka', 2, date(2018, 9, 9, 18), 'Nobody talks about the claw grip enough. Saved my fingertips.');
add('ka', 3, date(2024, 10, 1, 20), 'The rice cooker cheesecake is real?? Trying it tonight.');
add('ka', 3, date(2024, 10, 2, 21), 'Update: it is real and it is incredible');
add('pp', 0, date(2013, 7, 28, 23), 'first');
add('pp', 0, date(2016, 3, 11, 20), 'I still have one of these in a drawer somewhere. The battery life was unreal.');
add('pp', 1, date(2017, 5, 4, 14), 'Blowing into the cartridge never actually worked and I will never accept it');
add('pp', 1, date(2021, 8, 19, 22), 'The part about gold-plated contacts makes so much sense now');
add('pp', 2, date(2022, 2, 2, 16), 'That controller looks like it was designed by someone with three hands 😂');
add('pp', 2, date(2022, 2, 2, 17), 'I actually owned one. It was worse than it looks.');
add('on', 0, date(2016, 10, 30, 1), 'My brain after this video: 🤯');
add('on', 0, date(2023, 1, 15, 22), 'The part where the observable universe is just a bubble around us gave me chills');
add('on', 1, date(2019, 11, 3, 18), 'The pressure section was genuinely terrifying. Great animation work.');
add('on', 2, date(2024, 12, 8, 13), 'Wholeheartedly disagree with the #1 pick but respect the reasoning');
add('td', 0, date(2021, 6, 26, 7), 'That sunrise at the end made me book a trip. Thank you!');
add('td', 1, date(2022, 4, 10, 14), 'What sleeping pad are you using? Mine weighs more than your whole kit');
add('td', 2, date(2023, 3, 3, 12), 'Please always carry more water than you think you need. Great video though!');
add('mr', 0, date(2018, 2, 14, 21), 'I could watch an entire series just about river borders');
add('mr', 1, date(2025, 9, 9, 17), 'The island with one resident and three governments is the best story I have heard all year');
add('ptm', 0, date(2020, 12, 1, 16), 'I failed calculus twice and this is the first time any of it clicked');
add('ptm', 1, date(2015, 8, 22, 15), 'I refuse. 0.999… is just very very close to 1.');
add('ptm', 1, date(2021, 8, 22, 15), 'Update 6 years later: I accept it now.');
add('sl', 0, date(2025, 5, 18, 10), 'The collaring at the end 😮 so smooth');
add('sl', 1, date(2025, 6, 1, 19), 'Crawling glaze has ruined so many of my pieces. The bisque dust tip is going on my studio wall.');
add('gt', 0, date(2024, 8, 29, 18), 'My balcony tomatoes produced exactly four tomatoes this year. Four. Watching this for motivation.');
add('gt', 1, date(2026, 4, 22, 9), 'Started a compost bin because of this. My neighbors have questions.');
add('ms', 0, date(2023, 11, 11, 23), 'Track 4 at 2am on an empty highway is a religious experience');
add('ss', 0, date(2025, 2, 16, 3), 'That last split was unreal. Congrats on the record!!');
add('ll', 0, date(2022, 1, 20, 4), 'this stream got me through finals. thank you 💙');

// ---------------------------------------------------------------- live chats
const L = []; // live chats: [videoId, date, text, priceMicros]
const addL = (key, vi, d, text, price = 0) => L.push({ video: v(key, vi), d, text, price });
const ssDay = [2025, 2, 16];
[
  ['hello from Ohio!'], ['PB pace!!!'], ['that skip was so clean'], ['chat is he going to make it'],
  ['LETS GOOO'], ['Good luck on the final split! 🍀', 5000000], ['clip it clip it clip it'],
  ['the wall clip on the first try 😱'], ['first stream I caught live, this is awesome'], ['GG! Congrats on the WR 🏆', 20000000],
].forEach(([t, p], i) => addL('ss', 0, date(...ssDay, 1, 5 + i * 9), t, p));
[
  ['who is winning the relay?'], ['team blue has the momentum'], ['that handoff was perfect'],
  ['For the charity goal! 💚', 10000000], ['absolute scenes'],
].forEach(([t, p], i) => addL('ss', 1, date(2025, 8, 23, 1, 10 + i * 7), t, p));
[
  ['studying for my chem final, wish me luck'], ['good evening everyone 🌙'], ['this song is so calming'],
  ['anyone else here every night'], ['coffee #3 ☕'], ['thank you for keeping this going', 2000000],
  ['back again for thesis writing'], ['the rain sounds are perfect today'],
].forEach(([t, p], i) => addL('ll', 0, date(2023, 5, 7 + Math.floor(i / 3), 3, 12 + (i % 3) * 14), t, p));
[
  ['coding my first app tonight 💻'], ['bug fixed! celebrating with this playlist'], ['love this rainy one'],
  ['Keep the lights on 🏠', 5000000],
].forEach(([t, p], i) => addL('ll', 1, date(2026, 9, 12, 2, 20 + i * 11), t, p));

// ---------------------------------------------------------------- CSVs
const q = (s) => {
  const str = String(s ?? '');
  return /[",\n]/.test(str) ? '"' + str.replace(/"/g, '""') + '"' : str;
};
const csv = (header, rows) => [header, ...rows].map((r) => r.map(q).join(',')).join('\n') + '\n';
const segs = (text, mention) => {
  const parts = [];
  if (mention) parts.push({ text: mention.name, mention: { externalChannelId: mention.id } }, { text: ' ' + text });
  else parts.push({ text });
  return parts.map((p) => JSON.stringify(p)).join(',');
};

// The takeout's files, zipped once they're all written.
const entries = [];
const write = (rel, content) => entries.push({ name: `Takeout/YouTube and YouTube Music/${rel}`, data: Buffer.from(content, 'utf8') });

/** A zip of [files], stored uncompressed, dated when Google would have exported it. */
function zip(files) {
  const time = 18 << 11; // 18:00
  const day = ((2026 - 1980) << 9) | (9 << 5) | 27; // 2026-09-27
  const parts = [];
  const central = [];
  let offset = 0;
  for (const { name, data } of files) {
    const nameBytes = Buffer.from(name, 'utf8');
    const crc = crc32(data);
    const local = Buffer.alloc(30);
    local.writeUInt32LE(0x04034b50, 0);
    local.writeUInt16LE(20, 4); // version needed
    local.writeUInt16LE(0x0800, 6); // UTF-8 names
    local.writeUInt16LE(time, 10);
    local.writeUInt16LE(day, 12);
    local.writeUInt32LE(crc, 14);
    local.writeUInt32LE(data.length, 18);
    local.writeUInt32LE(data.length, 22);
    local.writeUInt16LE(nameBytes.length, 26);
    parts.push(local, nameBytes, data);
    const entry = Buffer.alloc(46);
    entry.writeUInt32LE(0x02014b50, 0);
    entry.writeUInt16LE(20, 4); // version made by
    entry.writeUInt16LE(20, 6); // version needed
    entry.writeUInt16LE(0x0800, 8);
    entry.writeUInt16LE(time, 12);
    entry.writeUInt16LE(day, 14);
    entry.writeUInt32LE(crc, 16);
    entry.writeUInt32LE(data.length, 20);
    entry.writeUInt32LE(data.length, 24);
    entry.writeUInt16LE(nameBytes.length, 28);
    entry.writeUInt32LE(offset, 42);
    central.push(entry, nameBytes);
    offset += local.length + nameBytes.length + data.length;
  }
  const directory = Buffer.concat(central);
  const end = Buffer.alloc(22);
  end.writeUInt32LE(0x06054b50, 0);
  end.writeUInt16LE(files.length, 8);
  end.writeUInt16LE(files.length, 10);
  end.writeUInt32LE(directory.length, 12);
  end.writeUInt32LE(offset, 16);
  return Buffer.concat([...parts, directory, end]);
}

const commentRows = C.map((c) => {
  const id = commentId();
  const parent = c.reply ? commentId() : '';
  return [c.reply ? `${parent}.${randStr(22, AZ09)}` : id, own.id, ts(c.d), '0', parent, '', c.video, segs(c.text, c.reply), parent || id];
});
write('comments/comments.csv', csv(
  ['Comment ID', 'Channel ID', 'Comment Create Timestamp', 'Price', 'Parent Comment ID', 'Post ID', 'Video ID', 'Comment Text', 'Top-Level Comment ID'],
  commentRows));
write('live chats/live chats.csv', csv(
  ['Live Chat ID', 'Channel ID', 'Live Chat Create Timestamp', 'Price', 'Currency code', 'Video ID', 'Live Chat Text'],
  L.map((l) => [liveChatId(), own.id, ts(l.d), String(l.price), l.price ? 'USD' : '', l.video, segs(l.text)])));
write('channels/channel.csv', csv(
  ['Channel ID', 'Channel Description (Original)', 'Channel Tag 1', 'Channel Title (Original)', 'Channel Visibility'],
  [[own.id, 'Mostly here for the comments section.', '', own.title, 'Public']]));
write('channels/channel URL configs.csv', csv(['Channel ID', 'Channel Vanity URL 1 Name'], [[own.id, own.handle]]));
write('subscriptions/subscriptions.csv', csv(['Channel Id', 'Channel Url', 'Channel Title'],
  channels.filter((c) => !['mr', 'ms'].includes(c.key)).map((c) => [c.id, `http://www.youtube.com/channel/${c.id}`, c.title])));

// ---------------------------------------------------------------- history
const allVideoIds = Object.keys(videos);
const weights = { bsb: 5, ka: 4, dcr: 4, fw: 3, on: 3, pp: 3, tw: 2, td: 2, ll: 2, ptm: 2 };
const weighted = allVideoIds.flatMap((id) => Array(weights[videos[id].channel.key] ?? 1).fill(id));
const watches = [];
for (let day = 0; day < 21; day++) {
  const n = 4 + Math.floor(rand() * 6);
  for (let i = 0; i < n; i++) {
    const id = pick(weighted);
    const vid = videos[id];
    const d = new Date(Date.UTC(2026, 8, 27 - day, 14 + Math.floor(rand() * 12), Math.floor(rand() * 60), Math.floor(rand() * 60), Math.floor(rand() * 1000)));
    watches.push({
      header: 'YouTube',
      title: `Watched ${vid.title}`,
      titleUrl: `https://www.youtube.com/watch?v=${id}`,
      subtitles: [{ name: vid.channel.title, url: `https://www.youtube.com/channel/${vid.channel.id}` }],
      time: d.toISOString(),
      products: ['YouTube'],
      activityControls: ['YouTube watch history'],
    });
  }
}
watches.sort((a, b) => b.time.localeCompare(a.time));
write('history/watch-history.json', JSON.stringify(watches, null, 2));

const queries = ['cheap weather station sensor', 'how to desolder smd', 'crispy potatoes oven', 'sourdough starter not rising',
  'ultralight sleeping pad', 'e ink display arduino', 'best compost bin for apartment', 'lofi rain', 'speedrun world record',
  'jupiter size comparison', 'how to center a vase on the wheel', 'walnut desk organizer plans', 'cat dishwasher',
  'trailer editing tricks', 'balcony tomato varieties', '0.999 equals 1 proof', 'island with three governments',
  'petg stringing fix', 'rice cooker cheesecake', 'glaze crawling fix'];
const searches = [];
for (let i = 0; i < 34; i++) {
  const s = pick(queries);
  const d = new Date(Date.UTC(2026, 8, 27 - Math.floor(i * 21 / 34), 13 + Math.floor(rand() * 10), Math.floor(rand() * 60)));
  searches.push({
    header: 'YouTube', title: `Searched for ${s}`,
    titleUrl: `https://www.youtube.com/results?search_query=${s.replace(/ /g, '+')}`,
    time: d.toISOString(), products: ['YouTube'], activityControls: ['YouTube search history'],
  });
}
searches.sort((a, b) => b.time.localeCompare(a.time));
write('history/search-history.json', JSON.stringify(searches, null, 2));
fs.writeFileSync(path.join(OUT, 'takeout-20260927T180000Z-001.zip'), zip(entries));

// ---------------------------------------------------------------- seed + images
const videoCache = {};
for (const [id, vid] of Object.entries(videos)) {
  videoCache[id] = {
    videoId: id, channelId: vid.channel.id, channelTitle: vid.channel.title, title: vid.title,
    description: null, thumbnailUrl: `https://i.ytimg.com/vi/${id}/mqdefault.jpg`, publishedAt: null,
  };
}
const avatarUrl = (id) => `https://yt3.ggpht.com/ytc/${id}=s176-c-k-c0x00ffffff-no-rj`;
const thumbCache = Object.fromEntries([own, ...channels].map((c) => [c.id, avatarUrl(c.id)]));
fs.writeFileSync(path.join(OUT, 'seed.json'), JSON.stringify({
  cached_video_metadata: JSON.stringify(videoCache),
  cached_channel_thumbnails: JSON.stringify(thumbCache),
}));
fs.writeFileSync(path.join(OUT, 'images.json'), JSON.stringify({
  avatars: [own, ...channels].map((c) => ({ id: c.id, emoji: c.emoji, colors: c.colors, monogram: !!c.monogram })),
  thumbs: Object.values(videos).map((vid, i) => ({
    id: vid.id, title: vid.title, emoji: vid.channel.emoji, colors: vid.channel.colors, live: !!vid.channel.live, variant: i % 4,
  })),
}, null, 1));
console.log(`takeout: ${commentRows.length} comments, ${L.length} live chats, ${watches.length} watched, ${searches.length} searches`);
