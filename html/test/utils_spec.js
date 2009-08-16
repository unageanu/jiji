
describe('util.PathUtils#basenameの動作確認', {
  '"aaa/bbb.txt" → "bbb.txt" ': function() {
    value_of(util.PathUtils.basename("aaa/bbb.txt")).should_be("bbb.txt");
  },
  '"/aaa/ccc/bbb" → "bbb" ': function() {
    value_of(util.PathUtils.basename("/aaa/ccc/bbb")).should_be("bbb");
  },
  '"aaa/日本語" → "日本語" ': function() {
    value_of(util.PathUtils.basename("aaa/日本語")).should_be("日本語");
  },
  '"日本語" (スラッシュを含まない) → "日本語" ': function() {
    value_of(util.PathUtils.basename("日本語")).should_be("日本語");
  },
  '"日本語/" (スラッシュが末尾) → "" ': function() {
    value_of(util.PathUtils.basename("日本語/")).should_be("");
  },
  '"/" (スラッシュのみ) → "" ': function() {
    value_of(util.PathUtils.basename("/")).should_be("");
  },
  '"" (空文字列) → "" ': function() {
    value_of(util.PathUtils.basename("")).should_be("");
  },
  'null → "" ': function() {
    value_of(util.PathUtils.basename(null)).should_be("");
  },
  'undefined → "" ': function() {
    value_of(util.PathUtils.basename(undefined)).should_be("");
  }
});

describe('util.PathUtils#dirnameの動作確認', {
  '"aaa/bbb.txt" → "aaa" ': function() {
    value_of(util.PathUtils.dirname("aaa/bbb.txt")).should_be("aaa");
  },
  '"/aaa/ccc/bbb" → "/aaa/ccc" ': function() {
    value_of(util.PathUtils.dirname("/aaa/ccc/bbb")).should_be("/aaa/ccc");
  },
  '"/a/日本語/日本語" → "/a/日本語" ': function() {
    value_of(util.PathUtils.dirname("/a/日本語/日本語")).should_be("/a/日本語");
  },
  '"日本語" (スラッシュを含まない) → "" ': function() {
    value_of(util.PathUtils.dirname("日本語")).should_be("");
  },
  '"日本語/" (スラッシュが末尾) → "" ': function() {
    value_of(util.PathUtils.dirname("日本語/")).should_be("日本語");
  },
  '"/" (スラッシュのみ) → "" ': function() {
    value_of(util.PathUtils.dirname("/")).should_be("");
  },
  '"" (空文字列) → "" ': function() {
    value_of(util.PathUtils.dirname("")).should_be("");
  },
  'null → "" ': function() {
    value_of(util.PathUtils.dirname(null)).should_be("");
  },
  'undefined → "" ': function() {
    value_of(util.PathUtils.dirname(undefined)).should_be("");
  }
});

describe('util.PathUtils#isChildの動作確認', {
  'path:"aaa/bbb/ccc", dir:"aaa/bbb",  → true ': function() {
    value_of(util.PathUtils.isChild("aaa/bbb/ccc", "aaa/bbb")).should_be(true);
  },
  'path:"aaa/bbb/ccc", dir:"aaa",  → true ': function() {
    value_of(util.PathUtils.isChild("aaa/bbb/ccc", "aaa")).should_be(true);
  },
  'path:"aaa/bbb/ccc", dir:"aaa/ccc",  → false ': function() {
    value_of(util.PathUtils.isChild("aaa/bbb/ccc", "aaa/ccc")).should_be(false);
  },
  'path:"aaa/bbb/ccc", dir:"aaa/bbbb",  → false': function() {
    value_of(util.PathUtils.isChild("aaa/bbb/ccc", "aaa/bbbb")).should_be(false);
  },
  'path:"aaa/bbb/ccc", dir:"aaa/bb",  → false': function() {
    value_of(util.PathUtils.isChild("aaa/bbb/ccc", "aaa/bb")).should_be(false);
  },
  'path:"日本語/ccc", dir:"日本語",  → true': function() {
    value_of(util.PathUtils.isChild("日本語/ccc", "日本語")).should_be(true);
  },
  'path:"/日本語/ccc", dir:"",  → true': function() {
    value_of(util.PathUtils.isChild("/日本語/ccc", "")).should_be(true);
  },
  'path:"", dir:"",  → true': function() {
    value_of(util.PathUtils.isChild("", "")).should_be(false);
  }
});

describe('util.PathUtils#normarizeの動作確認', {
  '基本のパターン': function() {
    value_of(util.PathUtils.normarize([
      "aaa/bbb",
      "aaa",
      "aa",
      "aa/xx",
      "aa/cc/dd",
      "aa/cc",
      "bb/dd/ss",
      "bb/dd",
      "cc/xx"
    ])).should_be([
      "aa",
      "aaa",
      "bb/dd",
      "cc/xx"
    ]);
  },
  '空の配列': function() {
    value_of(util.PathUtils.normarize([])).should_be([]);
  }
});