GetMatchingBrace(brace) {
    switch brace {
        case '{': return '}'
        case '[': return ']'
        case '(': return ')'
        case '}': return '{'
        case ']': return '['
        case ')': return '('
    }
}
