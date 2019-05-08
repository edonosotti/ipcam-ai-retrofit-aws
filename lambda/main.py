import logging
import os

logger = logging.getLogger()
logger.setLevel(logging.DEBUG)

def lambda_handler(event, context):
    logger.debug('##### ENVIRONMENT VARIABLES')
    logger.debug(os.environ)
    logger.debug('##### EVENT')
    logger.debug(event)
