const tokenfile = joinpath(tempdir(), "24cb59ae-a5a4-11e9-0ec9-534fb6590556")
const SERVER = "http://3.9.208.37/graphql/"
const query = """
    {
      experiments {
        objectId
        description
        name
        runs {
          objectId
          factorLevels {
            factor {
              name
            }
            level {
              value
            }
            createdDate
          }
          runDate
        }
      }
    }
"""
tokenquery(username, password) = """
    mutation {
      tokenAuth(username: "$username", password: "$password") {
        token
      }
    }
"""
validityquery(token) = """
mutation {
  verifyToken(token: "$token") {
    payload
  }
}
"""
const username_dialog = Dialog()

function getcredentials()
    username = requestᵐ("Username: ", username_dialog)
    io = Base.getpass("Password")
    password = read(io, String)
    Base.shred!(io)
    username, password
end

function gettoken()
    if isfile(tokenfile)
        open(tokenfile) do io
            token = readline(io)
        end
        r = Queryclient(SERVER, validityquery(token))
        r.Info.status == 200 || error("couldn't verify token")
        j = JSON3.read(r.Data)
        if unix2datetime(j[:data][:verifyToken][:payload][:exp]) > now() + Minute(1)
            return token
        end
    end
    username, password = getcredentials()
    r = Queryclient(SERVER, tokenquery(username, password))
    r.Info.status == 200 || error("couldn't authenticate with server")
    j = JSON3.read(r.Data)
    token = j[:data][:tokenAuth][:token]
    open(tokenfile, "w") do io
        println(io, token)
    end
    return token
end

function getexperimentsruns(token)
    r = Queryclient(SERVER, query, auth = "JWT $token")
    r.Info.status == 200 || error("couldn't query server")
    r.Data
end


