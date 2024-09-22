local db = exports["u5_sqlite"]

print(
    json.encode(
        db:select("users", {"name","age"}, {id=1})
    )
)