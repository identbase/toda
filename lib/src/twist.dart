/*
  twist_hash BLOB NOT NULL,
  line_twist BLOB NOT NULL,
  prev_hash BLOB,
  twist_json TEXT NOT NULL,
  raw_bytes BLOB NOT NULL,
  locked_for_publisher TEXT,
  locked_for_publisher_at INTEGER,
  published_as_successor_at INTEGER,
  published_as_named_at INTEGER,
  created_at INTEGER DEFAULT CURRENT_TIMESTAMP NOT NULL,
  last_updated_at INTEGER DEFAULT CURRENT_TIMESTAMP NOT NULL
*/
class Twist {

}
