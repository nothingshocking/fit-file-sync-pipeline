# Contributing to FIT File Sync Pipeline

Thank you for considering contributing! This project aims to help athletes sync workout data between platforms seamlessly.

## How to Contribute

### Reporting Bugs

Found a bug? Please [open an issue](https://github.com/yourusername/fit-file-sync-pipeline/issues) with:

- **Clear title** describing the problem
- **Steps to reproduce** the issue
- **Expected behavior** vs. actual behavior
- **Log excerpts** (redact API keys!)
- **System information** (Windows version, PowerShell version)
- **Fit-File-Faker version:** `pipx list | Select-String fit-file-faker`

### Suggesting Features

Have an idea? [Open an issue](https://github.com/yourusername/fit-file-sync-pipeline/issues) with:

- **Clear description** of the feature
- **Use case** - why would this be useful?
- **Proposed solution** if you have one
- **Alternatives considered**

### Code Contributions

1. **Fork the repository**
2. **Create a feature branch:**
```powershell
   git checkout -b feature/your-feature-name
```

3. **Make your changes:**
   - Follow existing code style
   - Add comments for complex logic
   - Update documentation if needed

4. **Test your changes:**
   - Run scripts with `-DryRun` flag
   - Verify no existing functionality breaks
   - Test edge cases

5. **Commit with clear messages:**
```powershell
   git commit -m "Add feature: brief description"
```

6. **Push to your fork:**
```powershell
   git push origin feature/your-feature-name
```

7. **Open a Pull Request** with:
   - Description of changes
   - Why the change is needed
   - Testing performed

### Documentation

Documentation improvements are always welcome!

- Fix typos or unclear instructions
- Add examples or use cases
- Improve troubleshooting steps
- Translate to other languages

## Development Guidelines

### PowerShell Style

- Use **verb-noun** function names: `Get-Activities`, `Process-File`
- Include **comment-based help** for functions
- Use **approved verbs:** `Get-Verb` to see list
- Handle **errors gracefully** with try-catch

### Commit Messages

- Use present tense: "Add feature" not "Added feature"
- Be descriptive but concise
- Reference issues: "Fix #123: Description"

### Testing

Before submitting:
```powershell
# Test with dry run
.\scripts\monitor-and-sync.ps1 -RunOnce -DryRun

# Verify no errors in logs
Get-Content logs\sync-*.log -Tail 50
```

## Code of Conduct

### Our Standards

- Be respectful and inclusive
- Welcome newcomers
- Accept constructive criticism
- Focus on what's best for the community

### Unacceptable Behavior

- Harassment or discriminatory language
- Trolling or insulting comments
- Publishing others' private information
- Other unprofessional conduct

## Questions?

- **General questions:** [Open a discussion](https://github.com/yourusername/fit-file-sync-pipeline/discussions)
- **Bugs:** [Open an issue](https://github.com/yourusername/fit-file-sync-pipeline/issues)
- **Security concerns:** Email directly (don't open public issue)

## License

By contributing, you agree that your contributions will be licensed under the MIT License.

## Acknowledgments

Contributors will be recognized in the README. Thank you for helping improve this project!
