# ccTune
A simple ComputerCraft music player for your playlists.

Inspired by [cc-music-player](https://github.com/Metalloriff/cc-music-player)

## Features

- **Playlist Generator**: Easily create playlists tailored to your musical taste! 🎵
- **Online Playback**: Say goodbye to file size limits! Stream your music directly from the cloud! ☁️
- **Simple Installation**: Get up and running in no time! 🛠️
- **Modular Design**: Add support for more file hosts effortlessly! 🔌
- **Custom Playlist Format**: Enjoy the simplicity of the `.cctpl` format for your playlists! 📂

## Instalation

Ready to dive in?
Open up your ComputerCraft terminal and fetch the install script with this command:

```
wget https://raw.githubusercontent.com/jiriks74/ccTune/refs/heads/main/install.lua
```

Then, run the installer:

```
install
```

## Usage

### Creating a playlist

1. Convert your `.mp3` files into `.dfpwm` files
  - [I personally use `music.madefor.cc`](https://music.madefor.cc/)
2. Download your `.dfpwm` files into some directory
3. Upload those files to some cloud
  - Currently only Nextcloud is supported
4. Get a share link for the folder the files are in
5. Run the script generation utilitiy:

```bash
lua playlistGenerator.lua my_playlist.cctpl --type Nextcloud --baseUrl https://nextcloud.example.com/s/myMusicFolder --directory /path/to/DFPWM/directory
```

### Playing your songs

1. Open your computer
2. Drad and drop the playlist into Minecraft
3. Run the `play` command with the playlist name

```
play myplaylist.cctpl
```
4. Now, you're all set to enjoy your music with ccTune! 🎉

> [!Tip]
> You can shuffle the playlist with the `-s` or `--shuffle` parameter:
> ```
> play myplaylist.cctpl -s
> ```

