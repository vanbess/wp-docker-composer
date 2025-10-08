# Contributing to WordPress Docker Composer Environment

Thank you for your interest in contributing! This project aims to make WordPress development easier for everyone.

## 🤝 How to Contribute

### Reporting Issues
- Use the [issue tracker](https://github.com/your-username/wp-docker-composer/issues)
- Search existing issues before creating a new one
- Provide detailed information about your environment
- Include steps to reproduce the problem

### Suggesting Features
- Open a [discussion](https://github.com/your-username/wp-docker-composer/discussions) first
- Explain the use case and benefits
- Consider if it fits the project's scope

### Code Contributions
1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Test thoroughly
5. Submit a pull request

## 🛠️ Development Setup

### Prerequisites
- Docker and Docker Compose
- Git
- Basic knowledge of shell scripting (for composer.sh changes)

### Local Development
```bash
# Fork and clone your fork
git clone https://github.com/your-username/wp-docker-composer.git
cd wp-docker-composer

# Create feature branch
git checkout -b feature/your-feature-name

# Set up environment
cp .env.example .env
# Edit .env with your settings

# Start development environment
docker-compose up -d
./composer.sh install

# Test your changes
./composer.sh doctor
```

## 📝 Guidelines

### Code Style
- Use clear, descriptive variable names
- Add comments for complex logic
- Follow existing code patterns
- Keep functions focused and small

### Shell Script Guidelines (composer.sh)
- Use proper error handling
- Provide informative output messages
- Add timeout protection for external commands
- Include fallback mechanisms

### Documentation
- Update README.md for new features
- Add examples for new commands
- Update version constraints guide if needed
- Keep documentation clear and beginner-friendly

### Testing
- Test on multiple environments when possible
- Verify all commands work as expected
- Check error handling and edge cases
- Test the setup process from scratch

## 🔍 Testing Checklist

Before submitting a pull request:

### Basic Functionality
- [ ] `docker-compose up -d` starts all services
- [ ] `./composer.sh install` completes successfully
- [ ] WordPress is accessible at configured port
- [ ] phpMyAdmin is accessible
- [ ] `./composer.sh doctor` reports healthy status

### Plugin Management
- [ ] Plugin installation works
- [ ] Plugin removal works (both safe and force)
- [ ] Version management (upgrade/downgrade) works
- [ ] Search functionality works

### Theme Management
- [ ] Theme installation works
- [ ] Theme removal works
- [ ] Theme activation works

### Error Handling
- [ ] Commands timeout appropriately
- [ ] Graceful fallbacks work
- [ ] Clear error messages are shown
- [ ] Partial failures are handled

### Documentation
- [ ] README.md is updated
- [ ] New commands are documented
- [ ] Examples are provided
- [ ] Help text is accurate

## 📋 Pull Request Process

1. **Create descriptive title**: "Add plugin search functionality" vs "Fix bug"

2. **Provide detailed description**:
   - What changes were made
   - Why they were needed
   - How to test the changes

3. **Reference related issues**: Use "Fixes #123" or "Relates to #456"

4. **Keep changes focused**: One feature/fix per PR

5. **Update documentation**: Include relevant doc updates

### PR Template
```markdown
## Description
Brief description of changes

## Type of Change
- [ ] Bug fix
- [ ] New feature
- [ ] Documentation update
- [ ] Performance improvement

## Testing
- [ ] Tested locally
- [ ] All existing tests pass
- [ ] New tests added (if applicable)

## Checklist
- [ ] Code follows project guidelines
- [ ] Documentation updated
- [ ] No breaking changes (or properly documented)
```

## 🏷️ Versioning

This project follows [Semantic Versioning](https://semver.org/):
- **Major** (1.0.0): Breaking changes
- **Minor** (0.1.0): New features, backward compatible
- **Patch** (0.0.1): Bug fixes, backward compatible

## 🎯 Areas for Contribution

### High Priority
- Platform compatibility (Windows, macOS improvements)
- Performance optimizations
- Additional error handling
- More comprehensive testing

### Medium Priority
- Additional WP-CLI integrations
- Custom Docker image optimizations
- Backup/restore functionality
- SSL/HTTPS support

### Low Priority
- UI improvements for management script
- Additional package repositories
- Integration with CI/CD systems

## 💡 Ideas Welcome

We're always looking for ways to improve! Some areas where ideas are especially welcome:

- **Developer Experience**: Make setup even easier
- **Performance**: Faster startup times, better caching
- **Features**: New functionality that helps WordPress developers
- **Documentation**: Better guides, tutorials, examples
- **Testing**: Automated testing, better validation

## 🏆 Recognition

Contributors will be:
- Listed in the README.md
- Mentioned in release notes
- Given credit in commit messages

## 📞 Getting Help

- 💬 [Discussions](https://github.com/your-username/wp-docker-composer/discussions)
- 📧 Create an issue for bugs or questions
- 📖 Check existing documentation first

## 🙏 Thank You

Every contribution helps make WordPress development better for everyone. Whether it's reporting a bug, suggesting a feature, improving documentation, or writing code - thank you for helping!

---

**Remember**: The best contribution is the one that makes life easier for fellow WordPress developers! 🚀