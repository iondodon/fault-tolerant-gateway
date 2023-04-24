use serde::{Deserialize, Serialize};
use warp::Filter;
use reqwest::Client;
use std::env;

#[derive(Serialize, Deserialize)]
struct RegisterRequest {
    service: String,
    address: String,
}

async fn register_service(client: Client, registry_url: String, service: String, address: String) {
    let register_url = format!("{}/register", registry_url);
    let register_request = RegisterRequest { service, address };

    println!("Sending request to register this service replica to Service Registry");

    match client.post(&register_url).json(&register_request).send().await {
        Ok(response) => {
            if response.status().is_success() {
                println!("Service registered successfully");
            } else {
                eprintln!("Failed to register service: {:?}", response.text().await);
            }
        }
        Err(e) => {
            eprintln!("Error registering service: {:?}", e);
        }
    }
}

async fn hello() -> Result<impl warp::Reply, warp::Rejection> {
    let address = match env::var("ADDRESS") {
        Ok(value) => value,
        Err(_e) => panic!("Could not get ADDRESS"),
    };

    println!("New request in replica {}", address);

    Ok(format!("Hello from Rust web service - {address}"))
}

#[tokio::main]
async fn main() {
    let service_name = match env::var("SERVICE_NAME") {
        Ok(value) => value,
        Err(_e) => panic!("Could not get SERVICE_NAME"),
    };
    let address = match env::var("ADDRESS") {
        Ok(value) => value,
        Err(_e) => panic!("Could not get ADDRESS"),
    };

    let client = Client::new();

    let registry_url = "http://gateway:7171".to_string();
    let address = format!("{address}:1234").to_string();

    register_service(client.clone(), registry_url, service_name, address).await;

    let hello_route = warp::path!("hello").and_then(hello);

    warp::serve(hello_route).run(([0, 0, 0, 0], 1234)).await;
}


