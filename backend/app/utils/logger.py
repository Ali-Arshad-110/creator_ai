"""
Structured logging configuration.
JSON-formatted logs for production, human-readable for development.
"""

import logging
import sys

from app.config import get_settings


def setup_logger(name: str = "creatorai") -> logging.Logger:
    """
    Configure and return the application logger.

    - Development: human-readable format with colors
    - Production: JSON-structured format for log aggregation
    """
    settings = get_settings()
    logger = logging.getLogger(name)

    if logger.handlers:
        return logger

    logger.setLevel(logging.DEBUG if settings.debug else logging.INFO)

    handler = logging.StreamHandler(sys.stdout)

    if settings.environment == "production":
        formatter = logging.Formatter(
            '{"time":"%(asctime)s","level":"%(levelname)s",'
            '"module":"%(module)s","message":"%(message)s"}'
        )
    else:
        formatter = logging.Formatter(
            "%(asctime)s | %(levelname)-8s | %(module)s | %(message)s",
            datefmt="%H:%M:%S",
        )

    handler.setFormatter(formatter)
    logger.addHandler(handler)

    return logger
