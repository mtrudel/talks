theme: Inter
text: #EEEEEE
text-emphasis: #EEEEEE
text-strong: Menlo Bold, line-height(1.2)
header-emphasis: Helvetica Bold, #AAAAAA
code: auto(42), Menlo, line-height(1.2)
footnote: #EEEEEE, text-scale(1.4)
footer-style: #BBBBBB, text-scale(2), alignment(right)
build-lists: true

[.footer: github.com/mtrudel/talks]

#[Fit] Bandit on the loose! 
#[Fit] Networking in Elixir demystified
### @mattrudel - github.com/mtrudel - mat@geeky.net

^ Thank Jim & the team, Sophie & Meryl for MCing, all of you for coming to my talk

^ It really means a lot to have people take the time to be here, so thank all of you.

^ My name is mat, Toronto

^ The title of my talk is 'Bandit on the loose!, Networking in Elixir demystified'

^ My main goal with this talk is to take the wraps off of a pair of libraries that I've been
writing over the past year or so, named thousand island and bandit.

---
[.footer: github.com/mtrudel/thousand_island - github.com/mtrudel/bandit]

##[Fit] Introducing 
##[Fit] Thousand Island
##[Fit] & Bandit

^ They are ground up reimaginings of the Ranch and Cowboy projects, respectively. Both of these libraries represent pretty significant advancements in the state of the art of networking in Elixir, both from an ergonomic and also a performance perspective. I've had an absolute blast of a time working on them, and I'm so, so excited to finally show them off in public.

^ Another primary goal of this talk is described in its subtitle, and that is it to demystify lower level networking in Elixir. All too often, people consider networking code & server implementations as being unapproachable and intimidating, but in reality nothing could be further from the truth.

^ As Desmond said in his talk yesterday, all problems are solvable. Networking code is no different.  In fact, I would go so far as to say that lower level networking showcases some of the best that the BEAM and OTP have to offer. The patterns and features that set the BEAM apart really shine down here, and I'm super jazzed to take all of your on a tour of it

^ I'll be introducing Thousand Island and Bandit in due course during the tour, but in the meantime I've organized this talk along the lines that most people think about networking, and that's as a stack.  Specifically, we'll be looking at the stack that holds up Phoenix, and it looks like this:

---
#[Fit] Phoenix
#[Fit] Plug
#[Fit] HTTP
#[Fit] Sockets
#[Fit] TCP/IP

^ From lowest level to highest, TCP/IP, Sockets, HTTP, Plug, and finally Phoenix itself
^ So let's get at it, starting with TCP/IP, and starting more specifically with IP

---
#[Fit] *Phoenix*
#[Fit] *Plug*
#[Fit] *HTTP*
#[Fit] *Sockets*
#[Fit] TCP/IP

^ Should be around 2 minutes

---
# In the beginning there was IP (RFC 791)

* Provides each host on the network with an IP address
* 'Being connected to the internet' means[^1] having an IP yourself and being able to reach any other host via their IP
* All IP does is deliver packets to a host
* IP 'encapsulates' higher level protocols such as TCP and UDP
  * Identified by a unique 'Protocol Number' (TCP is 6, UDP is 17)

[^1]: A million caveats to this (NAT, the DFZ, \*cast, etc)

^ The important thing to note here is that IP really only addresses individual hosts; it does not provide any mechanism to address specific applications on a host

---
# Then came TCP (RFC 793)

* Provides application-level addressability
* Addressed by an IP & a port number
* Connections come in the form of a pair of reliable streams
* Each direction is a one-way stream of binary data
* Each direction is independent, can be shutdown, used simultaneously
* Commonly accessed via the 'Berkeley Socket API', part of libc

^ part of libc and shipped with just about every operating system today

---
#[Fit] *Phoenix*
#[Fit] *Plug*
#[Fit] *HTTP*
#[Fit] *Sockets*
#[Fit] TCP/IP

^ So that's TCP/IP. Probably the shortest of the five sections today, and frankly, probably review
for many of you, but foundational just the same. 

^ Should be around 3 minutes

---
#[Fit] *Phoenix*
#[Fit] *Plug*
#[Fit] *HTTP*
#[Fit] Sockets
#[Fit] *TCP/IP*

^ From here we move up the stack to sockets, where we actually start talking between remote processes

^ Be forewarned this will be the longest of the five sections, but it's also probably the most
interesting as in my experience this is the blurriest part of the stack for most people, so let's
jump in

---
# Berkeley sockets in a nutshell

* Clients **connect** to an IP/port pair
* Servers **bind** to a named port, and **listen** for connections
* Servers then **accept** clients' **connect** requests in a loop
* Once accepted, a TCP session is created between the client and the server
* The two peers can now **send** and **recv** data with one another
* At any time, either peer can **close** a connection

^ As mentioned at the end of the previous section, the TCP/IP stack is accessed via the Berkeley
Sockets API. It consists of about a half dozen or so functions, as follows

---
# How does Elixir access sockets?

* Via Erlang's **:gen_tcp** (and **:socket** since OTP 22)
* Provides nearly 1:1 mapping onto the standard Berkeley calls
* SSL is accessed via **:ssl** using ~identical functions
  * All the core socket abstractions are the same as TCP
  * `s/:gen_tcp/:ssl/`

^ Should be around 4 minutes

---
[.code-highlight: all]
[.code-highlight: 1]
[.code-highlight: 2]
[.code-highlight: 5]
[.code-highlight: 6,7]
[.code-highlight: 8]
[.code-highlight: 4-9]

# Simple :gen_tcp Server

```elixir
{:ok, listen_socket} = :gen_tcp.listen(4000, [active: false])
accept_and_handle(listen_socket)

def accept_and_handle(listen_socket) do
  {:ok, socket} = :gen_tcp.accept(listen_socket)
  :gen_tcp.send(socket, "Hello, World")
  :gen_tcp.close(socket)
  accept_and_handle(listen_socket)
end
```

---
[.code-highlight: all]
[.code-highlight: 1]
[.code-highlight: 2,3]
[.code-highlight: 4]

# Simple :gen_tcp Client

```elixir
{:ok, socket} = :gen_tcp.connect('localhost', 4000, [active: false])
{:ok, data} = :gen_tcp.recv(socket, 0)
IO.puts(data) #=> "Hello, World"
:gen_tcp.close(socket)
```
^ Should be around 5 minutes

---
# The Stack So Far

![Original](network_stack_gen_tcp.pdf)

---
# Socket Review

* This is all you *really* need to implement a server
* Working this low level is tedious
* Performant patterns are non-trivial
* Usually abstracted by a 'socket server'

---
# What is a Socket Server?

* Provides a useful abstraction of raw sockets
* Sits underneath an e.g. HTTP server
* Listens for client connections over TCP/SSL
* Hands individual connections off to an upper protocol layer
* Handles transport concerns (SSL/TLS negotiation, connection draining, etc)
* Does this efficiently and scalably

---
# Who is a Socket Server?

* Ranch is the current goto implementation of such a server on the BEAM
* Thousand Island[^2] is a new pure-Elixir socket server, inspired by Ranch but with numerous improvements

[^2]: Get it? They're both salad dressings?!?

---
[.footer: github.com/mtrudel/thousand_island]

#[Fit] Thousand Island
##[Fit] A pure Elixir socket server, embodying OTP ideals

* Fast (performance basically equal to Ranch)
* Simple (1.7k LoC, about ½ the size of Ranch)
* Comprehensive documentation & examples
* Supports TCP, TLS & Unix Domain sockets
* Loads of config options
* Fully wired for telemetry, including socket-level tracing
* Extremely simple & powerful Handler behaviour

^ Should be around 7 minutes

---
[.code-highlight: all]
[.code-highlight: 2]
[.code-highlight: 5,7,8,9]
[.footer: github.com/mtrudel/thousand_island]

# Let's build RFC867 (Daytime)

```elixir
defmodule Daytime do
  use ThousandIsland.Handler

  @impl ThousandIsland.Handler
  def handle_connection(socket, state) do
    time = DateTime.utc_now() |> to_string()
    ThousandIsland.Socket.send(socket, time)
    {:close, state}
  end
end

{:ok, pid} = ThousandIsland.start_link(handler_module: Daytime)
```

---
[.code-highlight: all]
[.code-highlight: 2]
[.code-highlight: 5-8]
[.footer: github.com/mtrudel/thousand_island]

# Let's build RFC862 (Echo)

```elixir
defmodule Echo do
  use ThousandIsland.Handler

  @impl ThousandIsland.Handler
  def handle_data(data, socket, state) do
    ThousandIsland.Socket.send(socket, data)
    {:continue, state}
  end
end

{:ok, pid} = ThousandIsland.start_link(handler_module: Echo)
```

^ Should be around 9 minutes

---
[.footer: github.com/mtrudel/thousand_island]
# Thousand Island Handler Process

* 1 process per connection
* **ThousandIsland.Handler** module is just a **GenServer**
* Your connection processes can do all the normal **GenServer** things
* Receives are async by default (via **handle_data/3**)
* Free to write 'traditional' blocking network code if you wish, anywhere
* **start_link** based escape hatch if you need it (you probably won't)

---
[.footer: github.com/mtrudel/thousand_island]
# Thousand Island Process Model

* Handler processes are hosted within a process tree
* Rooted in the **ThousandIsland.start_link/1** call which starts the server
* Process tree is entirely self-contained
* Multi-level process tree designed to minimize contention
* Textbook example of how powerful OTP design patterns can be
* Check out the project README for more info

---
#[Fit] Thousand Island
## github.com/mtrudel/thousand_island

* Stable and suitable for general use
* `0.5.x` series is likely the last before a `1.0`
* Big ideas for the future, but the foundation is solid

^ So that's Thousand Island. To summarize the state of the project
^ Big ideas around multi-node setups & managing clusters of thousand-island nodes
^ But the foundation you've seen here is and will remain solid
^ Should be around 11 minutes

---
# The Stack So Far

![Original](network_stack_socket_server.pdf)

^ We're at the end of our socket tour now, and are moving up to HTTP

---
#[Fit] *Phoenix*
#[Fit] *Plug*
#[Fit] HTTP
#[Fit] *Sockets*
#[Fit] *TCP/IP*

---
# What is HTTP?

* HTTP/1.x is just plain text over sockets. Defined primarily by RFC 2616

^ Note that https is just this same thing over an SSL socket

^ No substantial protocol layer changes, just what sort of transport it runs over

---
[.code-highlight: all]
[.code-highlight: 1]
[.code-highlight: 2-3]
[.code-highlight: 5]
[.code-highlight: 7]
[.code-highlight: 8-9]
[.code-highlight: 11]

[.build-lists: false]
# What is HTTP?

* HTTP/1.x is plain text over sockets. Defined primarily by RFC 2616

```
  > GET /thing/12 HTTP/1.1
  > host: www.example.com
  > [... other headers ...]
  > [empty line]
  > [body content]

  < HTTP/1.1 200 OK
  < content-length: 123
  < [... other headers ...]
  < [empty line]
  < [body content]
```

---
[.code-highlight: all]
[.code-highlight: 2]
[.code-highlight: 5-8]

# Let's build a simple HTTP server

```elixir
defmodule HelloWorldHTTP do
  use ThousandIsland.Handler

  @impl ThousandIsland.Handler
  def handle_data(_data, socket, state) do
    ThousandIsland.Socket.send(socket, "HTTP/1.0 200 OK\r\n\r\nHello, World")
    {:close, state}
  end
end
```

---
# What does an HTTP server do?

* A complete HTTP/1.x implementation isn't *that* much more complicated
* Parses & validates request and header lines (and possibly request body)
* Sends conformant responses back to the client

---
# Who is an HTTP server?

* Cowboy is the current goto HTTP server on the BEAM
  * Complete HTTP/1.1, HTTP/2 & WebSocket server
* I've written Bandit[^3], a new pure-Elixir HTTP server for Plug applications

[^3]: Get it? They're both tropes within a heavily romanticized & largely fictional American mythology?!?

^ Cowboy does HTTP1.x as above, and also handles HTTP/2 and WebSocket connections, which we'll see more about in a few minutes

^ I've written Bandit, a new pure-Elixir HTTP server for plug applications

---
[.footer: github.com/mtrudel/bandit]

#[Fit] Bandit
##[Fit] An HTTP Server for Plug Applications

* Written 100% in Elixir
* Plug-native
* Robust HTTP/1.1 and HTTP/2 conformance
* Written from the ground up for correctness, performance & clarity
* Incredible performance (more later!)

---
# Making an HTTP server do useful things

* So, HTTP servers return content to clients, but *what* content?
* The content from our app, obviously
* But how to hand off to app logic?
* Enter Plug

^ Should be around 14 minutes

---
#[Fit] *Phoenix*
#[Fit] Plug
#[Fit] *HTTP*
#[Fit] *Sockets*
#[Fit] *TCP/IP*

---
[.code-highlight: all]
[.code-highlight: 4-6]
[.code-highlight: 4]
[.code-highlight: 5]
[.code-highlight: 4-6]
[.footer: github.com/elixir-plug/plug]

# Plug
### An abstraction of HTTP Request/Response Pairs

```elixir
defmodule HelloWorldPlug do
  def init(opts), do: opts

  def call(%Plug.Conn{} = conn, _opts) do
    Plug.Conn.send_resp(conn, 200, "Hello, World")
  end
end
```

^ Mention similarity to rack in the ruby world
^ So Plug is pretty simple at its core, but it's actually very powerful
^ It's powerful largely because the library comes with a bunch of useful plugs built-in

---
[.footer: github.com/elixir-plug/plug]
# Plug Comes With Batteries Included

* Plug comes with built-in Plugs to:
  * Create pipelines
  * Route requests
  * Manage sessions
  * Parse request bodies
  * *Lots* more
* This is enough for a LOT of applications

^ This is enough for a LOT of applications

^ In fact the original project that spurred on the development of Bandit runs on these basic building blocks to this day. 

^ I'm going to take a quick minute to highlight this, as I think it's a useful tool that many people may not be aware of

---
[.footer: github.com/mtrudel/hap]

# Aside: Bandit & Thousand Island's Origin Story

* Written to support HAP, a HomeKit Accessory Protocol library for Nerves
* Runs over HTTP, but with a twist (custom encryption on bare TCP)

^ Started trying to write in ranch, gave up, and now we have Thousand Island and Bandit as a result

^ So this TCP encryption chichanery is one thing

---
[.footer: github.com/mtrudel/hap]
[.build-lists: false]

# Aside: Bandit & Thousand Island's Origin Story

* Written to support HAP, a HomeKit Accessory Protocol library for Nerves
* Runs over HTTP, but with a twist (custom encryption on bare TCP)
* HTTP layer is simple, runs entirely on **Plug.Router**:

```elixir
  defmodule HAP.EncryptedHTTPServer do
    use Plug.Router

    post "/pairings" do ....
    get "/accessories" do ....
  end
```

^ So this TCP encryption is one thing, but the HTTP that happens on top is very very simple, and
runs entirely on Plug's built in Plug.Router module

^ Plug.Router provides a simple DSL that allows you to match against HTTP requests and craft
responses in a very lightweight manner

^ Reformed rubyists may recognize this as being very similar to Sinatra, and it is

^ If you ever find yourself thinking that Phoenix is too heavy for a particular job, I would suggest looking at Plug.Router as it may fit your needs quite well

^ Turning back to the Plug stack, let's look at how web servers call into Plugs

---
# Plug Servers

* Plug is implemented in Cowboy via the **Plug.Cowboy** adapter
* Bandit is Plug-Native

^ In the Cowboy world, this is done via the Plug.Cowboy library which adapts Cowboy's internal handler behaviour into the Plug pattern. 

^ Bandit has a leg up here because it's Plug-native

^ And this looks like this

---
# The Stack So Far

![Original](network_stack_plug.pdf)

^ Now that we're done with Plug, we can finally take a quick look at Phoenix and hot it fits into
things

---
#[Fit] Phoenix
#[Fit] *Plug*
#[Fit] *HTTP*
#[Fit] *Sockets*
#[Fit] *TCP/IP*

---
# Enter Phoenix

* The HTTP part of Phoenix is 'just' a Plug
* Phoenix's WebSocket support is a different thing (more later)
* Not much more to say about things here
* This is as high in the stack as we're going today

^ This probably shouldn't surprise many people, but Phoenix, at least the HTTP part, is just
a plug

---
# The Full Stack (Finally)

![Original](network_stack_phoenix.pdf)

^ Summarize how things flow up and name each layer in the stack. 

^ So now that we've described the entire stack and where Bandit fits into it, let's take the remainder of this talk to go over Bandit and why I believe it's such a compelling alternative to Cowboy

^ Should be around 18 minutes

---
[.footer: github.com/mtrudel/bandit]

#[Fit] Bandit
##[Fit] An HTTP Server for Plug Applications

* Built on top of Thousand Island
* Full support for HTTP/1.x & HTTP/2
  * Scores 100% on h2spec in **--strict** mode (runs in CI)
* Clear, Approachable, Idiomatic Elixir

^ h2spec is a Go application and is the gold standard conformance suite for http2. We run it in CI in strict mode, in addition to a full battery of ex_unit tests

---
[.footer: github.com/mtrudel/bandit]
# Bandit is a Plug-First Server

* No impedance mismatches
* Less (and clearer) code (<3k LoC today, about ⅓ of Cowboy)
* *Incredibly* fast and memory efficient

^ Compared to 10k + for Cowboy + Cowboy.plug

^ And I personally think these numbers are pretty incredible...

---
[.footer: github.com/mtrudel/network_benchmark]

#[Fit] Up to 5x Faster Than Cowboy

![inline](benchmark_chart.pdf)

^ Anywhere from 1.5x - 5x faster than Cowboy in apples to apples benchmarks.

^ I want to be clear here; I'm not juicing these numbers at all. This is as good faith of a comparison as I'm capable of doing as a non-professional benchmarker. 

^ In several cases I actually gave an advantage to Cowboy as it had some stability issues with certain workloads

^ Unless I missed something stupid, I really do believe the perf numbers are this good

^ Benchmark process & overview is available at the repo listed in the footnote if you'd like to review

^ This is possible due to the streamlined approach we take to serve requests. 

^ Let's look at this, starting with HTTP/1

---
[.footer: github.com/mtrudel/bandit]
# HTTP/1.1 In Bandit

* 1 process per connection
* 1:1 mapping between Handler **handle_data/3** calls and Plug **call/2** calls
* Straightforward, 'linear' code

^ Not a lot of 'there' there

---
[.footer: github.com/mtrudel/bandit]
[.build-lists: false]
# HTTP/2 In Bandit

* Quite a bit harder

---
[.footer: github.com/mtrudel/bandit]
# HTTP/2 In A Nutshell
### Framed binary protocol

![Original](http2.pdf)

^ Primary design goal is to allow a single connection to service multiple HTTP requests simultaneously

^ Does this by multiplexing requests using small 'frames', each corresponding to a request (the protocol calls these streams)

^ At any time the client may be sending headers for one request, the body of another, while the server is returning the body for a completely different request

^ This is all quite a bit to handle, and we do it like this:

---
[.footer: github.com/mtrudel/bandit]
# HTTP/2 In Bandit

* 1 process per connection + 1 process per stream
* Connection process implements **ThousandIsland.Handler**
* Stream processes are the ones that make Plug calls
* Full support for flow control, push promises, all the goodies
* `iodata` everywhere for speed and memory awesomeness

^ Connection process 'faces' the client

^ Stream processes 'face' the Plug API

---
[.footer: github.com/mtrudel/bandit]
# Where Is Bandit Today?

* HTTP/2 implementation complete & exhaustively tested (0.3.x)
* HTTP/1.1 implementation undergoing refactor & test improvements (0.4.x)
* Suitable for non-production Plug apps (not Phoenix, yet)
* Drop-in replacement for Cowboy where appropriate

^ Should be around 24 minutes

---
[.footer: github.com/mtrudel/bandit]
# Future Plans for Bandit

* Phoenix Support
    * Requires WebSocket support (coming in 0.5.x)
    * Note that WebSocket support is outside the scope of Plug
    * Requires Phoenix integration (coming in 0.7.x)
* Continue to improve perf and Cowboy migration story
* 'PR Campaign' to drive adoption
* HTTP/3 Support (distant future)

^ Note that Phoenix implements websockets by reaching into cowboy's protocol behaviours

---
# The Goal:

---
# The Goal:
#[Fit] Become the de-facto
#[Fit] networking stack 
#[Fit] for Elixir & the BEAM
#[Fit] \(along with Thousand Island\)

^ I would like to see Bandit as the default choice for new Phoenix installs, 

^ To be the stack of choice that people reach for for all manner of networking in the BEAM, along with Thousand Island

^ Judging by the response I've received so far, especially with Thousand Island, there's a lot of excitement in being able to so easily start wiring up low level networking applications

^ Really excited to see where this goes

---
[.footer: github.com/mtrudel/bandit]
# Working With Our Friends

* Work within Phoenix needed to add Bandit support 
    * Possibly generalize its WebSocket interface
* Code sharing with the Mint HTTP client (Thanks Andrea & Eric for HPAX)
* Improve iolist primitives in ERTS
* Other minor upstream improvements (eg. URI canonicalization & trailer support in Plug)
* To be clear: Cowboy & Ranch are awesome projects


^ Andrea and Eric were gracious enough to factor out their HTTP/2 header compression library into
the HPAX project, which is now shared between Mint and Bandit. Thank you both.
^ Cowboy and Ranch are and continue to be awesome projects and remain a great choice
^ I very much intend for this 'competition' to be friendly
^ Andrea Leopardi & Eric Meadows-Jönsson
^ Loïc (loi-eek)

---
[.footer: github.com/mtrudel/bandit]
#[Fit] Contribute!

* Fun, foundational work
* Grassroots project
* Contributions are *extremely* welcome
    * Core HTTP/1.1 & WebSocket work
    * Property-based testing suite
    * Security review & mitigation
    * Profiling & perf improvements / automated testing
    * *Lots* more!

^ Should be around 27 minutes

^ At least personally, this is the type of work I enjoy most and am best at. 
^ Infrastructure code doesn't deserve the reputation it has as being unapproachable and mysterious. 
^ It's a grassroots project that I'm undertaking after hours
^ While resources are thin, there's also a huge opportunity for you to put a big mark on it

---
#[Fit] github.com...<br>/mtrudel/thousand_island<br>/mtrudel/bandit<br>/mtrudel/talks<br>@mattrudel (Twitter)<br>@mtrudel (Elixir Slack)<br>mat@geeky.net

^ This brings us to the end of my talk today

^ Hopefully you've come away with some new nugget of networking knowledge, and again I'd encourage anyone with even a passing interest in lower level networking code to take a look at bandit and thousand island. Again, a big part of their existence is to demystify networking code in Elixir, so don't be shy

^ We have a few minutes for questions now, but if anyone has questions that we don't get to that they either don't feel comfortable asking out loud, please feel free to reach out on Twitter, email or on the Elixir Slack.

^ And now we'll open the floor up to questions
