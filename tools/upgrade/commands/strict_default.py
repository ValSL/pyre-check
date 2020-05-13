# Copyright (c) 2016-present, Facebook, Inc.
#
# This source code is licensed under the MIT license found in the
# LICENSE file in the root directory of this source tree.

import argparse
import json
import logging
from pathlib import Path

from ..configuration import Configuration
from ..filesystem import LocalMode, add_local_mode
from ..repository import Repository
from .command import Command


LOG: logging.Logger = logging.getLogger(__name__)


class StrictDefault(Command):
    def __init__(self, arguments: argparse.Namespace, repository: Repository) -> None:
        super().__init__(arguments, repository)
        self._local_configuration: Path = arguments.local_configuration
        self._fixme_threshold: int = arguments.fixme_threshold
        self._lint: bool = arguments.lint

    def run(self) -> None:
        project_configuration = Configuration.find_project_configuration()
        local_configuration = self._local_configuration
        if local_configuration:
            configuration_path = local_configuration / ".pyre_configuration.local"
        else:
            configuration_path = project_configuration
        with open(configuration_path) as configuration_file:
            configuration = Configuration(
                configuration_path, json.load(configuration_file)
            )
            LOG.info("Processing %s", configuration.get_directory())
            configuration.add_strict()
            configuration.write()
            all_errors = configuration.get_errors()

            if len(all_errors) == 0:
                return

            for path, errors in all_errors:
                errors = list(errors)
                error_count = len(errors)
                if error_count > self._fixme_threshold:
                    add_local_mode(path, LocalMode.UNSAFE)

            if self._lint:
                self._repository.format()
