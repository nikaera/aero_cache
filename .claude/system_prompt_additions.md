# Flutter & Dart Development Best Practices

## CORE ARCHITECTURE PRINCIPLES

### Feature-Based Architecture
- Organize code by features, not by technical layers
- Each feature should be self-contained with its own models, services, and UI components
- Use the following structure:
  ```
  lib/
     core/               # Shared utilities, constants, exceptions
     features/           # Feature-based modules
        feature_name/
           data/       # Data sources, repositories, models
           domain/     # Business logic, entities, use cases
           presentation/ # UI, widgets, state management
     shared/             # Shared components across features
  ```

### Clean Architecture Principles
- Follow Uncle Bob's Clean Architecture with clear separation of concerns
- Dependencies should point inward: Presentation → Domain → Data
- Domain layer should be pure Dart with no Flutter dependencies
- Use dependency injection for loose coupling

## DART LANGUAGE BEST PRACTICES

### Type Safety & Null Safety
- Always use explicit typing when it improves code clarity
- Leverage Dart's null safety features properly
- Use late keyword sparingly and only when necessary
- Prefer nullable types over late initialization when possible
- Use sealed classes for sum types and state modeling

### Code Quality Standards
- Write self-documenting code with meaningful names
- Keep functions small and focused (max 30 lines, ideally 10-15)
- Use const constructors and const values wherever possible
- Prefer composition over inheritance
- Follow Effective Dart guidelines for naming conventions

### Error Handling
- Create custom exception hierarchies that extend appropriate base classes
- Use Result/Either types for operations that can fail
- Provide meaningful error messages with context
- Never catch and ignore exceptions without proper handling
- Use sealed classes for error state modeling

## FLUTTER BEST PRACTICES

### Widget Design
- Prefer StatelessWidget over StatefulWidget when possible
- Break down complex widgets into smaller, reusable components
- Use const constructors for immutable widgets
- Implement proper widget keys for list items and dynamic content
- Create custom widgets instead of deeply nested widget trees

### State Management
- Choose appropriate state management solution based on complexity
- Keep state as local as possible
- Use immutable state objects
- Implement proper state restoration for navigation
- Consider using StateNotifier or similar for complex state logic

### Performance Optimization
- Use ListView.builder for large lists
- Implement proper widget disposal in dispose() methods
- Avoid expensive operations in build() methods
- Use RepaintBoundary for complex custom painting
- Optimize image loading with proper caching strategies

### Asset Management
- Organize assets by feature or type
- Use vector graphics (SVG) when possible for scalability
- Implement proper image caching and loading states
- Define asset constants to avoid magic strings

## TESTING STANDARDS

### Test Structure
- Follow the AAA pattern: Arrange, Act, Assert
- Write tests that describe behavior, not implementation
- Use descriptive test names that explain the scenario
- Group related tests using group() or describe()
- Maintain test independence - no shared mutable state

### Test Coverage
- Aim for high test coverage but focus on critical business logic
- Write unit tests for business logic and utility functions
- Include widget tests for complex UI components
- Add integration tests for critical user flows
- Mock external dependencies appropriately

### Test Organization
- Mirror your lib/ structure in test/
- Use factory methods or builders for test data creation
- Create reusable test utilities and matchers
- Keep test files focused and maintainable

## DEPENDENCY MANAGEMENT

### Package Selection
- Prefer well-maintained packages with good documentation
- Check package health scores and community support
- Avoid packages with frequent breaking changes
- Consider package size impact on app size
- Use dev_dependencies appropriately for development tools

### Version Management
- Use semantic versioning constraints appropriately
- Pin versions for critical dependencies
- Regularly update dependencies while testing thoroughly
- Document breaking changes in CHANGELOG.md

## CODE ORGANIZATION & DOCUMENTATION

### File Structure
- Use consistent naming conventions (snake_case for files)
- Organize imports: Dart SDK → Flutter → External packages → Internal
- Keep files focused on single responsibility
- Use barrel exports (index.dart) for clean public APIs

### Documentation
- Write comprehensive README with setup instructions
- Document public APIs with clear examples
- Use meaningful commit messages following conventional commits
- Maintain CHANGELOG.md for version tracking
- Include inline comments for complex business logic only

### Code Comments
- Avoid obvious comments that restate code
- Focus on explaining WHY, not WHAT
- Document complex algorithms and business rules
- Use TODO comments with context and assignee
- Remove obsolete comments during refactoring

## PERFORMANCE & OPTIMIZATION

### Memory Management
- Dispose of controllers, streams, and subscriptions properly
- Use weak references when appropriate
- Avoid memory leaks in long-lived objects
- Profile memory usage in development

### Build Optimization
- Use const constructors extensively
- Implement efficient shouldRebuild logic in custom widgets
- Minimize widget rebuilds through proper state management
- Use AnimatedBuilder for complex animations

### Network & Caching
- Implement proper HTTP caching strategies
- Use connection pooling and request deduplication
- Handle offline scenarios gracefully
- Implement progressive loading for large datasets

## SECURITY CONSIDERATIONS

### Data Protection
- Never store sensitive data in plain text
- Use secure storage for authentication tokens
- Implement proper certificate pinning for production
- Validate all user inputs
- Sanitize data before display

### API Security
- Use HTTPS for all network communication
- Implement proper authentication and authorization
- Handle API keys and secrets securely
- Add request/response logging for debugging (non-production)

## ACCESSIBILITY & INTERNATIONALIZATION

### Accessibility
- Provide semantic labels for all interactive elements
- Ensure proper color contrast ratios
- Support screen readers with meaningful descriptions
- Test with accessibility tools and real devices
- Implement proper focus management

### Internationalization
- Use Flutter's built-in l10n support
- Externalize all user-facing strings
- Consider text expansion in UI layouts
- Support RTL languages when applicable
- Test with different locales and languages

## CONTINUOUS INTEGRATION & QUALITY

### Code Quality Tools
- Use dart analyze with strict linting rules
- Implement pre-commit hooks for code formatting
- Run tests in CI/CD pipeline
- Use code coverage reporting
- Implement automated security scanning

### Release Management
- Use semantic versioning for releases
- Maintain proper branching strategy (GitFlow or GitHub Flow)
- Implement automated testing in multiple environments
- Use feature flags for gradual rollouts
- Monitor app performance and crash reporting

## DEVELOPMENT WORKFLOW

### Code Quality Command Sequence
ALWAYS follow this exact command sequence when checking code quality:

1. **Code Fixing**: `dart fix --apply` - Apply automated fixes first
2. **Code Formatting**: `dart format .` - Format all Dart files
3. **Static Analysis**: `dart analyze` - Check for issues and warnings
4. **Testing**: `flutter test` - Run tests (NEVER use `dart test` in Flutter projects)

This sequence ensures consistent code quality and prevents common issues.

### Code Review Standards
- Review for architecture adherence and best practices
- Check for proper error handling and edge cases
- Verify test coverage and quality
- Ensure documentation is updated
- Validate performance implications

### Development Environment
- Use consistent IDE settings across team
- Implement shared code formatting rules
- Use version-controlled development configurations
- Maintain consistent dependency versions
- Document setup requirements clearly

## MONITORING & MAINTENANCE

### Production Monitoring
- Implement comprehensive logging and monitoring
- Track key performance metrics and user flows
- Set up alerting for critical failures
- Monitor app size and performance over time
- Gather user feedback and analytics

### Technical Debt Management
- Regularly assess and refactor legacy code
- Update dependencies and address deprecations
- Maintain code quality through refactoring
- Document architectural decisions and trade-offs
- Plan technical debt reduction in sprint planning

These guidelines ensure high-quality, maintainable, and performant Flutter/Dart applications that scale effectively with team size and application complexity.

# File Editing Rule
Always ensure that any edited or newly generated text file ends with a newline character.
