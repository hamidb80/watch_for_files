# About
this is a cross-platform file watcher with database
it means you can save into DB the lastest files modification times
this special feature allows you to avoid unnecessary operations

# Usage

let's take a look at the defination of the main proc `goWatch`

```nim
proc goWatch*(
  folder: string, 
  tunnel: ptr Channel[ChangeFeed], 
  active: ptr bool,
  timeInterval: int, 
  dbPath: string = "", 
  save: bool = false
)
```

- `folder`: path to folder you wanna watch files changes, the program will watch file changes in any depths in that folder
- `tunnel`: a ptr to channel: changes will be sent to this channel
- `active`: a ptr to a bool: determines whether the worker [the file watcher] should continue to work or not
- `timeInterval`: the delay between every check
- `dbPath`: the database path
- `save`: a boolean that indicates whether the files modifications state should be saved after every check or not

**Note**: if you specify `dbPath` and the file exists there, the saved state is going to be restored before the first check

----------
you can find the example of usage in `tests/test.nim`