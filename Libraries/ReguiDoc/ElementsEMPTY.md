# :Label

<div align="left"><figure><img src="https://1061433021-files.gitbook.io/~/files/v0/b/gitbook-x-prod.appspot.com/o/spaces%2FbNfMkmxWyR6N5SCXKR8U%2Fuploads%2FeoQVTVAqCcLUJYlap9w3%2Fimage.png?alt=media&#x26;token=13dd2469-f260-4b82-9e8a-b35d7148c49c" alt=""><figcaption><p>Preview</p></figcaption></figure></div>

```typescript
type Label = {
	Text: string?,
	Bold: boolean?,
	Italic: boolean?,
	Font: string?
}
```

### Example usage:

```typescript
:Label({
    Text = "Hello world!"
})
```

### **Theme colors:**

| Tag      | Affects        |
| -------- | -------------- |
| Text     | Text color     |
| TextFont | Text fontface  |
| TextSize | Text font size |

