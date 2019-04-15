struct Camera {
	vec3 eye;
	vec3 dir;
	vec3 up;
    vec3 right;
};

struct Material {
	vec3 n;
    vec3 k;
};
	
struct Sphere {
    vec3 center;
    float radius;
    int materialId;
};
    
struct Ray {
    vec3 origin;
    vec3 direction;
};
    
struct Hit {
    vec3 rayOrigin;
    vec3 rayDirection;
    bool didHit;
    vec3 hitPoint;
    int hitMaterialId;
};
    
const Camera camera = Camera (
	vec3 (0.0, 0.0, 0.0),
	vec3 (0.0, 0.0, 1.0),
	vec3 (0.0, 1.0, 0.0),
    vec3 (1.0, 0.0, 0.0)
);

const Material gold = Material (
    vec3 (0.17, 0.35, 1.5),
    vec3 (3.1, 2.7, 1.9)
);
const Material silver = Material (
    vec3 (0.14, 0.16, 0.13),
    vec3 (4.1, 2.3, 3.1)
);

const Material [] MATERIALS = Material [] (gold, silver);

const Sphere sphere = Sphere (
    vec3 (0.0, 0.0, 1.0),
    0.4,
    0
);

Ray getRay (vec2 pixel) {
    vec3 dir = camera.dir + camera.right * pixel.x + camera.up * pixel.y - camera.eye;
    return Ray (camera.eye, normalize (dir));
}

Hit rayTrace (Ray ray) {
    
    Hit hit = Hit(
        ray.origin,
        ray.direction,
        false,
        vec3 (0.0),
        -1
    );
    
    vec3 dist = ray.origin - sphere.center;
    float a = dot (ray.direction, ray.direction);
    float b = dot (dist, ray.direction) * 2.0;
    float c = dot (dist, dist) - sphere.radius * sphere.radius;
    float discr = b * b - 4.0 * a * c;
    if (discr < 0.0) return hit;
    float sqrt_discr = sqrt (discr);
    float t1 = (-b + sqrt_discr) / 2.0 / a;
    float t2 = (-b - sqrt_discr) / 2.0 / a;
    if (t1 <= 0.0) return hit;
    float hitT = (t2 > 0.0) ? t2 : t1;
    hit.didHit = true;
    hit.hitPoint = ray.origin + ray.direction * hitT;
    hit.hitMaterialId = sphere.materialId;
    return hit;
}

void mainImage( out vec4 fragColor, in vec2 fragCoord ) {
    
    float aspect = iResolution.x / iResolution.y;
    
    vec2 pixel = vec2 (
        ((fragCoord.x / iResolution.x * aspect) - 0.5) * 2.0,
        ((fragCoord.y / iResolution.y) - 0.5) * 2.0
    );
    vec3 color = vec3 (0.0);
    
    Hit hit = rayTrace (getRay (pixel));
    
    if (hit.didHit) {
        color = vec3 (1.0);
    }

    fragColor = vec4(color, 1.0);
}