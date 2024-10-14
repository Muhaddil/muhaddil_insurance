# Muhaddil Insurance Script

## Overview
**Muhaddil Insurance** is a FiveM resource that adds a custom NPC, allowing players to purchase medical insurance in-game.

![Muhaddil Insurance](https://i.ibb.co/BBSVwrn/Captura-de-pantalla-2024-10-14-211902.png)

## Features

- Custom NPC to facilitate insurance purchases.
- Compatibility with both ESX and QBCore frameworks for FiveM.
- Medical insurance options that can be customized.
- Insurance details are stored in a SQL database.

## Requirements

- **ESX Framework**
  OR  
- **QBCore Framework**
- **SQL Database**: A properly configured SQL database to store player insurance data.

## Installation

1. **Download the Muhaddil Insurance Script** from the provided source.
2. **Unpack the files** into your server's `resources` folder.
3. **Configure your database**: Import the provided SQL file to set up the necessary database tables for storing insurance data.
4. **Edit the configuration files** to adjust any settings (such as NPC location, insurance types, and pricing).
5. **Add the script** to your server's `server.cfg` file, ensuring it starts correctly:
   ```bash
   ensure muhaddil_insurance
   ```
6. **Restart your server** to apply the changes.

## Compatibility

This script is compatible with both the **ESX** and **QBCore** frameworks. Ensure your server is using one of these frameworks before installation.

## License

This project is open-source and can be freely modified or redistributed under the terms of the [MIT License](LICENSE).

## Support

If you encounter any issues or have suggestions for improvement, feel free to open an issue or contribute to the project.
