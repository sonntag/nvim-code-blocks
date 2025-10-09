// Test JavaScript file for code block highlighting

function outerFunction() {
  console.log("outer start");

  function innerFunction() {
    console.log("inner start");
    if (true) {
      console.log("inside if");
      const x = 1;
      const y = 2;
    }
    console.log("inner end");
  }

  innerFunction();
  console.log("outer end");
}

class TestClass {
  constructor(name) {
    this.name = name;
  }

  method() {
    for (let i = 0; i < 10; i++) {
      if (i % 2 === 0) {
        console.log(`even: ${i}`);
      } else {
        console.log(`odd: ${i}`);
      }
    }
  }

  async asyncMethod() {
    try {
      const result = await fetch("https://api.example.com");
      return result.json();
    } catch (error) {
      console.error(error);
    }
  }
}

const arrowFunction = () => {
  return {
    nested: {
      deeply: {
        value: 42
      }
    }
  };
};

// Empty lines in block
function withEmptyLines() {
  const a = 1;

  const b = 2;

  return a + b;
}

outerFunction();
