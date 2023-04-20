import os
import argparse

def get_cwd() -> str:
    cwd = os.getcwd()
    return os.path.basename(cwd)

def format_release_badge(repo: str) -> str:
    badge_icon = f'https://img.shields.io/github/v/release/telia-oss/{repo}?style=flat-square'
    badge_link = f'https://github.com/telia-oss/{repo}/releases/latest'
    return f'[![latest release]({badge_icon})]({badge_link})'

def format_build_badge(repo: str) -> str:
    badge_icon = f'https://img.shields.io/github/actions/workflow/status/telia-oss/{repo}/main.yml?branch=master&logo=github&style=flat-square'
    badge_link = f'https://github.com/telia-oss/{repo}/actions/workflows/main.yml'
    return f'[![build status]({badge_icon})]({badge_link})'

def update_badges(file_path: str):
    repo = get_cwd()
    release_badge = format_release_badge(repo)
    build_badge = format_build_badge(repo)

    print(f'updating badges in README: {file_path}')
    with open(file_path, 'r+') as file:
        contents = file.readlines()

        release_index = -1
        build_index = -1

        for i, line in enumerate(contents):
            if line.startswith("[![latest release]"):
                print('found [![latest release] badge')
                release_index = i

            if line.startswith("[![build status]"):
                print('found [![build status] badge')
                build_index = i
            elif line.startswith("[![workflow]"):
                print('found [![workflow] badge')
                build_index = i

        if release_index == -1 and build_index == -1:
            print("Inserting both badges at start of README")
            release_index, build_index = 0, 1
        elif release_index == -1:
            print("Inserting release badge before build badge")
            release_index, build_index = build_index, build_index+1
            contents.insert(release_index, '\n')
        elif build_index == -1:
            print("Inserting build badge after release badge")
            build_index = release_index+1
            contents.insert(build_index, '\n')

        contents[release_index] = release_badge+'\n'
        contents[build_index] = build_badge+'\n'

        file.seek(0)
        file.writelines(contents)


def main():
    parser = argparse.ArgumentParser(description='Update badges in the repo README.md')
    parser.add_argument('-p', '--path', type=str, help='Path to the README file to update')
    args = parser.parse_args()

    update_badges(args.path)

if __name__ == '__main__':
    main()


