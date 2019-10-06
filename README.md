# docker.vim

Edit files in containers by vim running on local.

## Basic Commands

### Edit a file in a container

```vim
:DockerEdit container_name:/tmp/example.txt
```

This command copy the content of /tmp/example.txt in the container named container_name to the tmp file, and open it.
When execute `:w`, the content of the tmp file is written to /tmp/example.txt in the container.

### Wirte to the file in a container

```vim
:DockerWrite container_name:/path/to/file
```

This command write the content of current file to the /path/to/file in the container named container_name.
If you want to upddate /path/to/file in the container automatically on executing `:w`, use `:DockerWriteEdit` instead.

### Execute a script in a container

```vim
:DockerPlay
```

This command execute the content of a file in a container.
If asyncrun.vim is installed, this is executed via `:AsyncRun` .

#### Example

First, run a container.

```sh
docker container run --security-opt seccomp=unconfined -itd --rm --name swift swift
```

Second, open sample.swift and edit.

```swift
print("Hello World")
```

The extension of the file is important. It is used to determine the container in which the script is executed and the way execution.

Then, execute `:DockerPlay`.

#### Containers in which script is executed

The container in which the script is executed and the way execution is configured by `g:docker_play_containers` as follows

```vim
let g:docker_play_containers = {
\   'py': {'container': 'python', 'cmd': ['python']},
\   'swift': {'container': 'swift', 'cmd': ['swift']},
\}
```

Keys of `g:docker_play_containers` are file extensions.
The value of `container` is a name of container in which script is executed.
The value of `cmd` is a list of the command and arguments to execute the script.
In case of sample.py, `:DockerPlay` equivalents to `docker container exec python python sample.py`.

## Example of working with a project

In this example, assuming that a docker container named 'docker-vim' is running.

```sh
docker run -itd --name docker-vim ubuntu
```

### Configure a project

Write the file ~/.docker-vim.json as follows.

```json
{
  "projects": [
    {
      "container": "docker-vim",
      "container_dir": "/tmp",
      "local_dir": "~/path/to/dir"
    }
  ]
}
```

This configuration map docker-vim:/tmp to the local directory ~/path/to/dir.
Then commands `:DockerUpload`, `:DockerDownload` and `:DockerDiffFile` is avaiable in the ~/path/to/dir directory.

### Upload current file to the docker container

Open the file ~/path/to/dir/example.txt in vim and write something.
After save with `:w`, execute `:DockerUpload`.
When `:DockerUpload` is executed, the content of current file is copyied to the docker container `docker-vim:/tmp/example.txt`.

### Download the file in the docker container to current file

Open the file ~/path/to/dir/example.txt in vim and execute `:DockerDownload`.
When `:DockerDownload` is executed, the content of the file in docker container (in example, docker-vim:/tmp/example.txt) is copyied to the current file.

### Compare files in local and docker container

Open file ~/path/to/dir/example.txt in vim, then execute `:DockerDiffFile`.
Differences between ~/path/to/dir/example.txt and docker-vim:/tmp/example.txt are shown in diff-mode.
