# App Icon

Place the application icon here as `icon.png`.

## Requirements

- **Format**: PNG
- **Size**: 256x256 pixels (or 512x512 for high-DPI displays)
- **Transparency**: Recommended for better appearance

## Creating an Icon

### Option 1: Use an existing icon
Download a Windows Update or monitoring-themed icon from:
- [Flaticon](https://www.flaticon.com/)
- [Icons8](https://icons8.com/)
- [IconFinder](https://www.iconfinder.com/)

### Option 2: Create a custom icon
Use tools like:
- **Figma** (online)
- **Inkscape** (free vector editor)
- **Adobe Illustrator**
- **Canva**

### Option 3: Generate programmatically

You can use ImageMagick to create a simple placeholder:

```bash
# Create a simple 256x256 blue circle icon
convert -size 256x256 xc:transparent -fill "#4299e1" -draw "circle 128,128 128,30" icon.png
```

Or use Python with PIL:

```python
from PIL import Image, ImageDraw

# Create a 256x256 image with transparency
img = Image.new('RGBA', (256, 256), (0, 0, 0, 0))
draw = ImageDraw.Draw(img)

# Draw a blue circle
draw.ellipse([30, 30, 226, 226], fill='#4299e1')

# Draw a smaller white circle in the center
draw.ellipse([80, 80, 176, 176], fill='#ffffff')

# Save
img.save('icon.png')
```

## Icon Suggestions

Themes that work well:
- Windows logo with update arrows
- Gear/cog icon (representing updates)
- Chart/graph icon (representing monitoring)
- Shield with checkmark (representing system health)
- Computer monitor with metrics

## Note

The application will work without an icon, but the system tray functionality will not be enabled until an icon is provided at `assets/icons/icon.png`.
