# frozen_string_literal: true

module Vercon
  class Prompt
    END_SEQUENCE = "<END RESULT>"

    class << self
      def for_test_path(path:)
        system = <<~PROMPT.strip
          You are tasked as a professional Ruby and Ruby on Rails developer specialising in writing comprehensive RSpec unit tests for a Ruby class. You will receive a path to ruby file. Your objective is to generate a path corresponding RSpec unit test file. Make sure to use common practices used in Ruby on Rails community for structuring test file paths.

          Provide a in the following format:
          RUBY FILE PATH: "<expected path that user provided>"
          RSPEC FILE PATH: "<expected file path for RSpec file according to best practices>"
          #{END_SEQUENCE}

          Make sure to include "#{END_SEQUENCE}" at the end of your test source code. It's required.
        PROMPT

        user = <<~PROMPT.strip
          PATH: #{path.inspect}
        PROMPT

        {system: system, user: user, stop_sequences: [END_SEQUENCE]}
      end

      def for_test_generation(path:, source:, factories: nil, current_test: nil)
        system = <<~PROMPT.strip
          You are a professional Ruby developer specializing in writing comprehensive RSpec unit tests for a Ruby class. Your objective is to ensure each public method within the class is thoroughly tested. Below are the specifics you must adhere to:

          - Structure:
            - Organize your tests using `describe` and `context` blocks, ensuring there's a clear separation for each public method.
            - Use meaningful descriptions for each test scenario to enhance readability.

          - Coverage:
            - Achieve at least 95% coverage by testing all possible outcomes, including both success and failure cases.
            - For methods that can raise exceptions or handle errors, include tests that cover these scenarios.

          - Assertions:
            - Ensure your tests assert against all aspects of the method's behavior, including its return values, side effects (e.g., file operations), and state changes within the class.
            - Use appropriate RSpec matchers to make assertions clear and expressive.

          - Best Practices:
            - Write clean, maintainable tests, avoiding redundancy and ensuring each test is self-contained.
            - Utilize RSpec's features like `let`, `before`, and `after` blocks to set up preconditions and clean up after tests as needed.
            - Follow RSpec naming conventions and style guidelines for consistency.

          - Mocking and Stubbing:
            - When necessary, use RSpec's built-in mocking and stubbing capabilities to isolate the class under test from its dependencies.
            - This allows for focused testing of the class's behavior without relying on external components.
            - Use mocks and stubs judiciously to avoid over-mocking and maintain the integrity of the tests.

          - Factories:
            - If the user provides an available factories list and the class interacts with a database or external services, use factories to create test data and simulate real-world scenarios.
            - Ensure that only factories provided by the user are used and make sure they are defined correctly and provide the necessary data for the tests.

          - Edge Cases and Boundary Conditions:
            - Consider and test edge cases and boundary conditions that may affect the behavior of the class.
            - This includes testing with empty or nil values, large or small input values, and any other relevant scenarios specific to the class.
            - Think critically about potential edge cases and ensure they are adequately covered in the tests.

          If the user provides "CURRENT RSPEC FILE", use it as a base for your tests, improve it, and extend it according to the Ruby file being tested. Ensure that the existing tests are updated to meet the specified requirements and that new tests are added to achieve comprehensive coverage of the class's public methods.

          Remember to focus on testing the behavior of the class rather than its implementation details. Aim for concise, readable, and maintainable tests that provide confidence in the correctness of the class. Use descriptive test names, keep tests isolated from each other, and follow RSpec best practices and conventions throughout your test suite.

          After you have created the RSpec tests for the Ruby class, make sure to call "write_test_file" tool with the test source code.
          You shouldn't comment your thinking process.
        PROMPT

        user = ["PATH: #{path.inspect}"]

        if factories
          user << <<~PROMPT.strip
            AVAILABLE FACTORIES:
            ```json
            #{JSON.dump(factories)}
            ```
          PROMPT
        end

        user << <<~PROMPT.strip
          CODE:
          ```ruby
          #{source}
          ```
        PROMPT

        if current_test
          user << <<~PROMPT.strip
            CURRENT RSPEC FILE:
            ```ruby
            #{current_test}
            ```
          PROMPT
        end

        tools = [
          {
            name: "write_test_file",
            description: "Tool to write the test file to disk",
            input_schema: {
              type: "object",
              properties: {
                source_code: {
                  type: "string",
                  description: "The source code of the test file to be written to disk. Make sure to include the complete test file content. Do not include any additional information, comments or markup."
                }
              },
              required: ["source_code"]
            }
          }
        ]

        {system: system, user: user.join("\n"), tools: tools}
      end
    end
  end
end
