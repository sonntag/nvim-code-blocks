# Test Python file for code block highlighting

def outer_function():
    print("outer start")

    def inner_function():
        print("inner start")
        if True:
            print("inside if")
            x = 1
            y = 2

        print("inner end")

    inner_function()
    print("outer end")


class TestClass:
    def __init__(self, name):
        self.name = name

    def method(self):
        for i in range(10):
            if i % 2 == 0:
                print(f"even: {i}")
            else:
                print(f"odd: {i}")

    async def async_method(self):
        try:
            result = await some_async_call()
            return result
        except Exception as e:
            print(f"Error: {e}")


def with_empty_lines():
    a = 1

    b = 2

    return a + b


# List comprehension with nested structure
result = [
    x * 2
    for x in range(10)
    if x % 2 == 0
]

# Dictionary with nested structure
config = {
    "name": "test",
    "nested": {
        "value": 42,
        "items": [1, 2, 3]
    }
}

if __name__ == "__main__":
    outer_function()
