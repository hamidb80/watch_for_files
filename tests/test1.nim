import unittest
import watch_for_files

suite "hey":
  test "can add":
    check add(5, 5) == 10
