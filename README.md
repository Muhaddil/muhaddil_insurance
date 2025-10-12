## Overview
**Muhaddil Insurance** is a FiveM resource that adds a custom NPC, allowing players to purchase medical insurance in-game.

<img src="https://github.com/Muhaddil/muhaddil_insurance/blob/main/readmeimages/1.png?raw=true" alt="Muhaddil Insurance" width="600"/>
<img src="https://github.com/Muhaddil/muhaddil_insurance/blob/main/readmeimages/2.png?raw=true" alt="Muhaddil Insurance" width="600"/>

## Features in v2.0

- Completely redesigned user interface with multiple selectable themes (Dark, Red, Blue, Purple, Green)
- Compatibility with both ESX and QBCore frameworks for FiveM
- Insurance selling system for medical jobs
- Configurable discounts for specific jobs
- Multiple customizable insurance types (Basic, Weekly, Full, Premium)
- Integration with OX Logger, OX Notifications, and OX Target
- Automatic cleanup of expired insurances
- Automatic version checking
- Command to sell insurance to other players
- Detailed permission configuration by job and rank
- Customizable map blips
- SQL database storage with automatic integration
- Customizable NPCs with configurable interaction distance

## Requirements

- **ESX Framework** OR **QBCore Framework**
- **ox_lib** and **oxmysql**
- **SQL Database**: A properly configured SQL database to store player insurance data.

## Installation

1. **Download the Muhaddil Insurance Script** from the provided source.
2. **Unpack the files** into your server's `resources` folder.
3. **Configure your database**: The script can automatically integrate the necessary SQL tables (Config.AutoRunSQL = true).
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