# Hello World

0. Run `mix nerves.new hello_nerves`.
1. Run `MIX_TARGET=rpi0 mix firmware.burn`

# GPIO Hello World

0. Add to mix.exs: 

```
	{:circuits_gpio, "~> 0.1"},
	{:nerves_firmware_ssh, "~> 0.3", targets: [:rpi, :rpi0, :rpi2, :rpi3, :rpi3a, :rpi4, :bbb, :x86_64]}
```

1. Run `MIX_ENV=rpi0 mix deps.get`
2. Add lib/hello_nerves/blinker.ex:
    ```
	defmodule HelloNerves.Blinker do
	  use Task

	  def start_link(arg) do
	    Task.start_link(__MODULE__, :run, [arg])
	  end

	  def run(_arg) do
	    {:ok, gpio} = Circuits.GPIO.open(26, :output)
	    blink(gpio)
	  end

	  def blink(gpio) do
	    Circuits.GPIO.write(gpio, 1)
	    Process.sleep(500)
	    Circuits.GPIO.write(gpio, 0)
	    Process.sleep(500)
	    blink(gpio)
	  end
	end
	```
4. Add lib/hello_nerves/button.ex:
    ```
	defmodule HelloNerves.Button do
	  use GenServer

	  require Logger
	  
	  def start_link(arg) do
	  	GenServer.start_link(__MODULE__, arg)
	  end

	  def init(_arg) do
	    {:ok, gpio} = Circuits.GPIO.open(16, :input)
		Circuits.GPIO.set_interrupts(gpio, :both)
	    Circuits.GPIO.set_pull_mode(gpio, :pullup)
		{:ok, %{gpio: gpio}}
	  end

	  def handle_info({:circuits_gpio, 16, _time, 0}, state) do
	  	Logger.info("Button Pressed")
		{:noreply, state}
	  end

	  def handle_info({:circuits_gpio, 16, _time, 1}, state) do
	  	Logger.info("Button Released")
		{:noreply, state}
	  end
	end
	```
1. Add to `application.ex`
2. Run `MIX_TARGET=rpi0 mix firmware`
3. Run `MIX_TARGET=rpi0 mix upload nerves.local`
4. Stay on console, ssh in, and reference click sounds in log.

