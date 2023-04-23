use serde::{Deserialize, Serialize};
use warp::Filter;
use reqwest::Client;

#[derive(Serialize, Deserialize)]
struct RegisterRequest {
    service: String,
    address: String,
}

async fn register_service(client: Client, registry_url: String, service: String, address: String) {
    let register_url = format!("{}/register", registry_url);
    let register_request = RegisterRequest { service, address };

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
    Ok("Hello from Rust web service!")
}

#[tokio::main]
async fn main() {
    let client = Client::new();
    let registry_url = "http://gateway:7171".to_string();
    let name: String = "client-service".to_string();
    let address: String = "client-service:8080".to_string();

    register_service(client.clone(), registry_url, name, address).await;

    let hello_route = warp::path!("hello").and_then(hello);

    warp::serve(hello_route).run(([127, 0, 0, 1], 8080)).await;
}


