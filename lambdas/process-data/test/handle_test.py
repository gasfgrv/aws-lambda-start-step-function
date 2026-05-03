from handler import handler, table


def __test_handler():
    event = {
        "key1": "value1",
        "key2": "value2",
        "key3": "value3"
    }

    handler(event, None)

    print(table.scan())


if __name__ == "__main__":
    __test_handler()
