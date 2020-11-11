# industry-monitor

An industry monitoring script for Dual Universe.

## Usage

The easiest way to use this script is to copy the contents of the `standalone.json` file, right-click on a programming board, and choose `Paste xxx`.

## Requirements

One or more of each of the following:

- programming board
- databank
- relay
- detection zone
- switch
- industry machines
- monitor

## Connections

The main monitoring station should be connected as follows:

                              ---------
zone --> switch --> relay --> |       | --> monitor
                              | board | 
              databank(s) --> |       | <-- industry(s)
                              ---------
                     
                                    

Satellite stations should be connected as follows:

                ---------
      relay --> |       | --> databank
                | board | 
industry(s) --> |       | 
                ---------


